local Vector = require "lib.hump.vector"

local maxRollback = config.network.maxRollback
local delay = config.network.delay
local RingBuffer = require "netcode.ring_buffer"

local NetworkManager = NetworkManager
local NetworkPackets = require "netcode.network_packets"

local function log(level, message)
    if not Debug or Debug.netcodeLog < level then
        return
    end
    if type(message) == "string" then
        print(message)
    else
        vardump(message)
    end
end

local stubInput = { [1] = Vector(0, 0), [2] = Vector(0, 0) }

local NetworkGame = {
    player = 1,
    opponent = 2,
    remotePlayerId = nil,
    states = RingBuffer(maxRollback),
    isPaused = false,
    inputs = {},
    replay = {},
    predictedInputs = {},
    confirmedFrame = delay,
    localFrame = 1,
    delay = delay
}

function NetworkGame:enter(prevState, game, localPlayer)
    if localPlayer == 1 then
        self.player = 1
        self.opponent = 2
    else
        self.player = 2
        self.opponent = 1
    end
    local netPlayers = NetworkManager:getPlayers("connected")
    for k, v in pairs(netPlayers) do
        self.remotePlayerId = k
        break -- @hack
    end

    self.localFrame = 1
    self.confirmedFrame = self.delay
    self.inputs = {}
    self.replay = {}
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
    NetworkManager:update(dt)

    local localInputs = self:getLocalInputs()
    self:addInputs(self.localFrame + self.delay, 1, localInputs)

    local localInputsPacket = NetworkPackets.Inputs(
        { Vector(800 - localInputs.x, 490 - localInputs.y) },
        self.localFrame + self.delay,
        self.confirmedFrame
    )
    NetworkManager:send(localInputsPacket)
    log(4, "Sent inputs for " .. self.localFrame + self.delay)

    local remoteInputsPackets = NetworkManager:receive("Inputs")
    for _, packet in ipairs(remoteInputsPackets) do
        self:handlePacket(packet)
    end

    local newConfirmedFrame = self:getConfirmedFrame()
    if newConfirmedFrame > self.confirmedFrame then
        self:handleRollback(newConfirmedFrame)
    end

    if not self.isPaused then
        log(3, "Advancing game. Frame: " .. self.localFrame)
        self:advanceFrame()
    end
    -- MVP2: sync and slow down if opponent is lagging
end

function NetworkGame:addInputs(frame, player, inputs)
    log(4, "ADD INPUTS: f: "..frame.." player:"..player.."")
    log(5, inputs)
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
        log(4, "Predicting inputs at frame " .. self.localFrame)
        inputs[self.opponent] = self:getPredictedInputs(self.localFrame, self.opponent)
        self.predictedInputs[self.localFrame] = { [self.opponent] = inputs[self.opponent] }
        log(4, "Predicted x="..inputs[self.opponent].x.." y="..inputs[self.opponent].y)
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

function NetworkGame:isFramePredictedCorrectly(frame, player)
    local confirmedInput = self.inputs[frame][player]
    local predictedInput = self.predictedInputs[frame][player]
    for k, v in pairs(confirmedInput) do
        if predictedInput and predictedInput[k] and predictedInput[k] == confirmedInput[k] then
            -- the prediction was right
        else
            return false
        end
    end
    return true
end

function NetworkGame:handleRollback(newConfirmedFrame)
    log(3, "Rolling back! Local:" .. self.localFrame .. " Conf:" .. self.confirmedFrame .. " New Conf:" .. newConfirmedFrame)
    while self.confirmedFrame < newConfirmedFrame do
        -- check if we predicted inputs right
        -- then just skip from last confirmedFrame to the last correctly predicted
        log(5, self.predictedInputs)
        local nextFrame = self.confirmedFrame + 1
        if not self.predictedInputs[nextFrame] then
            log(4, "We don't have predicted inputs for frame "..nextFrame)
            break
        end
        
        if self:isFramePredictedCorrectly(nextFrame, self.opponent) then
            log(3, "Frame " .. nextFrame .. " prediction was correct")
            log(3, "Set confirmed frame to " .. nextFrame)
            self.confirmedFrame = nextFrame
        else
            log(3, "Frame " .. nextFrame .. " was predicted wrong")
            break
        end
    end
    self.predictedInputs = {}

    -- then rollback to the last correctly predicted frame
    local rollback = self.localFrame - self.confirmedFrame
    if rollback <= 0 then
        self.confirmedFrame = newConfirmedFrame
        return
    end
    while rollback > 0 do
        log(4, "Dropping 1 frame")
        self.states:pop()
        rollback = rollback - 1
    end
    log(3, "Loading state")
    self.game:loadState(self.states:peek())
    if Debug and Debug.ballSpeedLog == 1 then
        vardump(self.game.ball.velocity:len())
    end
    -- advance frames untill we are at the present
    local newLocalFrame = self.localFrame
    self.localFrame = self.confirmedFrame
    log(2, "Fast forward from "..self.localFrame .. " to " .. newLocalFrame)
    while self.localFrame < newLocalFrame do
        log(4, "FF advancing game. Frame: " .. self.localFrame)
        self:advanceFrame()
    end
    self.confirmedFrame = newConfirmedFrame
end

function NetworkGame:advanceFrame()
    self.game:advanceFrame()
    self.localFrame = self.localFrame + 1
    local gameState = self.game:getState()
    self.states:push(gameState)
    if Debug and Debug.replayDebug == 1 then
        self.replay[self.localFrame] = gameState
    end
end

function NetworkGame:handlePacket(packet)
    if packet.player ~= self.remotePlayerId then
        print("Ignoring packet from unknown player " .. packet.player)
        return
    end
    packet = packet.packet
    local frame = packet.startFrame
    log(4, "Got inputs for frame "..frame..": ")
    log(5, packet.inputs)
    for _, input in ipairs(packet.inputs) do
        input = Vector(input.x, input.y) -- @fixme ?
        if frame < self.confirmedFrame then
            log(2, "Received conflicting packet for frame "..frame.." but frame " .. self.confirmedFrame .. " is confirmed")
        else
            self:addInputs(frame, self.opponent, input)
        end
        frame = frame + 1
    end
end

function NetworkGame:keypressed(key, scancode, isrepeat)
    if key == "escape" then
        -- @todo send disconnect to other player
        replay.inputs = self.inputs -- replay is global
        replay.states = self.replay
    end
end

function NetworkGame:draw()
    self.game:draw()
    if Debug and Debug.showFps == 1 then
        love.graphics.print(""..tostring(love.timer.getFPS( )), 2, 2)
    end
    love.graphics.print(self.localFrame, 2, 16)
end

return NetworkGame