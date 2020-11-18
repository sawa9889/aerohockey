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
    delay = 3
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
    if Debug and Debug.netcodeLog > 4 then
        print("Sent inputs for " .. self.localFrame + self.delay)
    end

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
        if Debug and Debug.netcodeLog > 1 then
            print("Advancing game. Frame: " .. self.localFrame)
        end
        self.game:advanceFrame()
        vardump(self.game.ball.velocity:len())
        self.localFrame = self.localFrame + 1
        self.states:push(self.game:getState())
    end
    -- MVP2: sync and slow down if opponent is lagging
end

function NetworkGame:addInputs(frame, player, inputs)
    if Debug and Debug.netcodeLog > 4 then
        print("ADD INPUTS: f: "..frame.." player:"..player.."")
        if Debug and Debug.netcodeLog > 5 then
            vardump(inputs)
        end
    end
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
        if self.inputs[frame + 1] and self.inputs[frame + 1][player] then
            local nextInput = self.inputs[frame + 1][player]
            return (lastInput + nextInput) / 2
        end
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
        if Debug and Debug.netcodeLog > 4 then
            print("Predicting inputs at frame " .. self.localFrame)
        end
        inputs[self.opponent] = self:getPredictedInputs(self.localFrame, self.opponent)
        self.predictedInputs[self.localFrame] = { [self.opponent] = inputs[self.opponent] }
        if Debug and Debug.netcodeLog > 4 then
            print("Predicted x="..inputs[self.opponent].x.." y="..inputs[self.opponent].y)
        end
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
        return true
    else
        return false
    end 
end

function NetworkGame:handleRollback(newConfirmedFrame)
    if Debug and Debug.netcodeLog > 3 then
        print("Rolling back! Local:" .. self.localFrame .. " Conf:" .. self.confirmedFrame .. " New Conf:" .. newConfirmedFrame)
    end
    while self.confirmedFrame < newConfirmedFrame do
        -- check if we predicted right
        -- then just skip from last confirmedFrame to the last correctly predicted
        if Debug and Debug.netcodeLog > 5 then
            vardump(self.predictedInputs)
        end
        if not self.predictedInputs[self.confirmedFrame + 1] then
            if Debug and Debug.netcodeLog > 4 then
                print("We don't have predicted inputs for frame "..self.confirmedFrame + 1)
            end
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
            if Debug and Debug.netcodeLog > 3 then
                print("Frame " .. self.confirmedFrame + 1 .. " prediction was correct")
                print("Set confirmed frame to " .. self.confirmedFrame + 1)
            end
            self.confirmedFrame = self.confirmedFrame + 1
        else
            if Debug and Debug.netcodeLog > 3 then
                print("Frame " .. self.confirmedFrame + 1 .. " was predicted wrong")
            end
            break
        end
    end
    self.predictedInputs = {}
    -- then we need to rollback to last correctly predicted frame
    local frame = self.confirmedFrame
    local rollback = self.localFrame - frame

    if rollback <= 0 then
        return
    end
    while rollback > 0 do
        if Debug and Debug.netcodeLog > 4 then
            print("Dropping 1 frame")
        end
        self.states:pop()
        rollback = rollback - 1
    end
    if Debug and Debug.netcodeLog > 1 then
        print("Loading state")
    end
    self.game:loadState(self.states:peek())
    vardump(self.game.ball.velocity:len())
    -- advance frames untill we are at the present
    local newLocalFrame = self.localFrame
    self.localFrame = self.confirmedFrame
    self.confirmedFrame = newConfirmedFrame
    if Debug and Debug.netcodeLog > 3 then
        print("Fast forward from "..self.localFrame .. " to " .. newLocalFrame)
    end
    while self.localFrame < newLocalFrame do
        if Debug and Debug.netcodeLog > 1 then
            print("FF advancing game. Frame: " .. self.localFrame)
        end
        self.game:advanceFrame()
        vardump(self.game.ball.velocity:len())
        self.localFrame = self.localFrame + 1
        self.states:push(self.game:getState())
    end
end

function NetworkGame:handlePacket(packet)
    if packet.type == NetworkPackets.types.inputs then
        local frame = packet.startFrame
        if Debug and Debug.netcodeLog > 4 then
            print("Got inputs for frame "..frame..": ")
            if Debug and Debug.netcodeLog > 5 then
                vardump(packet.inputs)
            end
        end
        for _, input in ipairs(packet.inputs) do
            input = Vector(input.x, input.y) -- wtf
            if frame < self.confirmedFrame then
                if Debug and Debug.netcodeLog > 2 then
                    print("Received conflicting packet for frame "..frame.." but frame " .. self.confirmedFrame .. " is confirmed")
                end
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
    if Debug and Debug.showFps == 1 then
        love.graphics.print(""..tostring(love.timer.getFPS( )), 2, 2)
    end
    love.graphics.print(self.localFrame, 2, 16)
end

return NetworkGame