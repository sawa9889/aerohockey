local Vector = require "lib.hump.vector"

local maxRollback = config.network.maxRollback
local RingBuffer = require "netcode.ring_buffer"

local NetworkPackets = require "netcode.network_packets"

local networkInput  = love.thread.getChannel("networkControl")
local networkOutput = love.thread.getChannel("networkOutput")

local networkManagerThread = love.thread.newThread("netcode/network_manager.lua")
networkManagerThread:start()

local stubInput = { [1] = Vector(0, 0), [2] = Vector(0, 0) }

local NetworkGame = {
    player = 1,
    opponent = 2,
    states = RingBuffer(maxRollback),
    isPaused = false,
    inputs = {},
    predictedInputs = {},
    confirmedFrame = delay,
    localFrame = 1,
    delay = 2
}

function NetworkGame:enter(prevState, game)
    self.localFrame = 1
    self.confirmedFrame = 1
    local i = 1
    while i <= self.delay do
        self.inputs[i] = stubInput
        i = i + 1
    end
    self.game = game
    self.game:init(function() return self:getGameInputs() end)
    self.states:push(self.game:getState())
end

function NetworkGame:update(dt)

    local localInputs = self:getLocalInputs()
    self:addInputs(self.localFrame + self.delay, 1, localInputs)
    networkInput:push( {
        command = "send", packet = NetworkPackets.Inputs(
            {
                Vector(800 - localInputs.x, 490 - localInputs.y)
            },
            self.localFrame + self.delay, self.confirmedFrame)
    } )
    print("Sent inputs for " .. self.localFrame + self.delay)

    while networkOutput:peek() do
        local channelMessage = networkOutput:pop()
        if channelMessage.type == "packet" then
            self:handlePacket(channelMessage.data)
        end
    end

    local newConfirmedFrame = self:getConfirmedFrame()
    if newConfirmedFrame > self.confirmedFrame then
        self:handleRollback(newConfirmedFrame)
    end

    if not self.isPaused then
        print("Advancing game. Frame: " .. self.localFrame)
        self.game:advanceFrame()
        self.localFrame = self.localFrame + 1
        self.states:push(self.game:getState())
    end
    -- MVP2: sync and slow down if opponent is lagging
end

function NetworkGame:addInputs(frame, player, inputs)
    print("ADD INPUTS")
    vardump(frame, player, inputs)
    if not self.inputs[frame] then
        self.inputs[frame] = {}
    end
    self.inputs[frame][player] = inputs
end

function NetworkGame:getLocalInputs()
    local x, y = love.mouse.getPosition()
    return Vector(x, y)
end

function NetworkGame:getPredictedInputs(frame, player)
    local lastInput = self.inputs[self.confirmedFrame][player]
    if frame > self.confirmedFrame and self.confirmedFrame > 1 then
        local prevInput = self.inputs[self.confirmedFrame - 1][player]
        return lastInput -- + ( lastInput - prevInput ) * ( frame - self.confirmedFrame )   -- that looks stupid
    else
        return lastInput
    end
end

function NetworkGame:getGameInputs()
    local inputs = {}
    for k,v in pairs(self.inputs[self.localFrame]) do
        inputs[k] = v
    end
    if not inputs then
        -- inputs = self.inputs[self.confirmedFrame]
    end
    if not inputs[self.opponent] then -- @todo: multiple opponents?
        print("Predicting inputs at frame " .. self.localFrame)
        inputs[self.opponent] = self:getPredictedInputs(self.localFrame, self.opponent)
        self.predictedInputs[self.localFrame] = { [self.opponent] = inputs[self.opponent] }
        print("Predicted x="..inputs[self.opponent].x.." y="..inputs[self.opponent].y)
    end
    return inputs
end

function NetworkGame:getConfirmedFrame()
    local frame = self.confirmedFrame
    local isConfirmed = true
    while isConfirmed do
        frame = frame + 1
        isConfirmed = self:isConfirmed(frame)
    end
    return frame - 1
end

function NetworkGame:isConfirmed(frame)
    if self.inputs[frame] and self.inputs[frame][self.opponent] and self.inputs[frame][self.player] then
        vardump(frame, self.inputs[frame], self.inputs[frame][self.opponent], self.inputs[frame][self.player])
        return true
    else
        return false
    end 
end

function NetworkGame:handleRollback(newConfirmedFrame)
    print("Rolling back! Local:" .. self.localFrame .. " Conf:" .. self.confirmedFrame .. " New Conf:" .. newConfirmedFrame)
    while self.confirmedFrame < newConfirmedFrame do
        -- check if we predicted right
        -- then just skip from last confirmedFrame to the last correctly predicted
        if not self.predictedInputs[self.confirmedFrame + 1] then
            print("We don't have inputs for frame "..self.confirmedFrame + 1)
            break
        end
        local confirmedInput = self.inputs[self.confirmedFrame + 1][self.opponent]
        local predictedInput = self.predictedInputs[self.confirmedFrame + 1][self.opponent]
        local isPredictedRight = true
        for k, v in pairs(confirmedInput) do
            if predictedInput and predictedInput[k] and predictedInput[k] == confirmedInput[k] then
                -- the prediction was right
            else
                isPredictedRight = false
            end
        end
        if isPredictedRight then
            print("Frame " .. self.confirmedFrame + 1 .. " prediction was correct")
            print("Set confirmed frame to " .. self.confirmedFrame + 1)
            self.confirmedFrame = self.confirmedFrame + 1
        else
            print("Frame " .. self.confirmedFrame + 1 .. " was predicted wrong")
            break
        end
    end
    self.predictedInputs = {}
    -- then we need to rollback to last correctly predicted frame
    local frame = self.confirmedFrame
    local rollback = self.localFrame - frame
    --vardump(self.states)
    while rollback > 1 do
        print("Dropping 1 frame")
        self.states:pop()
        rollback = rollback - 1
    end
    if rollback > 0 then
        print("Loading state")
        --vardump(self.states)
        self.game:loadState(self.states:pop())
        -- advance frames untill we are at the present
        local newLocalFrame = self.localFrame
        self.localFrame = self.confirmedFrame
        self.confirmedFrame = newConfirmedFrame
        print("Fast forward from "..self.localFrame .. " to " .. newLocalFrame)
        while self.localFrame < newLocalFrame do
            print("FF advancing game. Frame: " .. self.localFrame)
            self.game:advanceFrame()
            self.localFrame = self.localFrame + 1
            self.states:push(self.game:getState())
        end
    end
end

function NetworkGame:handlePacket(packet)
    if packet.type == NetworkPackets.types.inputs then
        local frame = packet.startFrame
        print("Got inputs for frame "..frame..": ")
        vardump(packet.inputs)
        for _, input in ipairs(packet.inputs) do
            input = Vector(input.x, input.y) -- wtf
            if frame < self.confirmedFrame then
                print("Received conflicting packet for frame "..frame.." but frame " .. self.confirmedFrame .. " is confirmed")
            else
                self:addInputs(frame, self.opponent, input)
            end
            frame = frame + 1
        end
    end
end

function NetworkGame:keypressed(key, scancode, isrepeat)
end

function NetworkGame:draw()
    self.game:draw()
end

return NetworkGame