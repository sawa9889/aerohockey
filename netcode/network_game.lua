local Vector = require "lib.hump.vector"

local maxRollback = config.network.maxRollback
local delay = config.network.delay
local syncSmoothing = config.network.syncSmoothing
local RingBuffer = require "netcode.ring_buffer"

local NetworkManager = NetworkManager
local NetworkPackets = require "netcode.network_packets"

local log = require 'engine.logger' ("netcodeLog")
local desyncLog = require 'engine.logger' ("desyncDebugLog")

local stubInput = { [1] = Vector(0, 0), [2] = Vector(0, 0) }

local NetworkGame = {
    player = 1,
    opponent = 2,
    disconnected = false,
    remotePlayerId = nil,
    states = RingBuffer(maxRollback+1),
    isPaused = false,
    inputs = {},
    replay = {},
    predictedInputs = {},
    confirmedFrame = delay,
    confirmedByRemoteFrame = 1,
    syncFrames = 0,
    displayFrame = 1,
    inputFrame = 1 + delay,
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
    self.disconnected = false

    self.displayFrame = 1
    self.inputFrame = self.displayFrame + self.delay
    self.confirmedFrame = self.delay
    self.confirmedByRemoteFrame = 1
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

    local remoteInputsPackets = NetworkManager:receive("Inputs")
    for _, packet in ipairs(remoteInputsPackets) do
        self:handleInputPacket(packet)
    end

    local newConfirmedFrame = self:getConfirmedFrame()
    if newConfirmedFrame > self.confirmedFrame then
        self:handleRollback(newConfirmedFrame)
    end

    if self:remotePlayerIsDisconnected() then
        self.isPaused = true
        if not self.disconnected then
            NetworkManager:close()
            self.disconnected = true
            log(2, "Remote player has disconnected!")
        end
        return
    end

    self.isPaused = ( self.displayFrame - self.confirmedFrame ) >= maxRollback

    self:calculateFrameAdvantage()
    if self.syncFrames >= 1 then
        self.syncFrames = self.syncFrames - 1
        self.isPaused = true
        log(3, "Waiting a frame to sync")
    end

    if self.isPaused then
        log(4, "The game is PAUSED")
    else
        local localInputs = self:getLocalInputs()
        self:addInputs(self.inputFrame, self.player, localInputs)

        if self.confirmedByRemoteFrame < self.displayFrame - self.delay then
            log(4, "Remote player may have lost some packets, sending from frame " .. self.confirmedByRemoteFrame)
            self:sendInputs(self.confirmedByRemoteFrame)
        else
            self:sendInputs(self.inputFrame)
        end

        log(3, "Advancing game. Frame: " .. self.displayFrame)
        self:advanceFrame()
        desyncLog(1, self.game.ball.velocity)
    end
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
    for k,v in pairs(self.inputs[self.displayFrame]) do
        inputs[k] = v
    end
    if not inputs then
        -- inputs = self.inputs[self.confirmedFrame]
    end
    if not inputs[self.opponent] then -- @todo: multiple opponents?
        log(4, "Predicting inputs at frame " .. self.displayFrame)
        inputs[self.opponent] = self:getPredictedInputs(self.displayFrame, self.opponent)
        self.predictedInputs[self.displayFrame] = { [self.opponent] = inputs[self.opponent] }
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
    log(3, "Rolling back! Local:" .. self.displayFrame .. " Conf:" .. self.confirmedFrame .. " New Conf:" .. newConfirmedFrame)
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
    local rollback = self.displayFrame - self.confirmedFrame
    if rollback <= 0 then
        self.confirmedFrame = newConfirmedFrame
        return
    end
    log(3, "Loading state from " .. self.displayFrame .. "-" .. rollback .. " ago")
    while rollback > 0 do
        log(4, "Dropping 1 frame")
        self.states:pop()
        rollback = rollback - 1
    end
    log(4, "Loading state")
    self.game:loadState(self.states:peek())
    desyncLog(1, self.game.ball.velocity)
    -- advance frames untill we are at the present
    local newdisplayFrame = self.displayFrame
    self.displayFrame = self.confirmedFrame
    log(2, "Fast forward from "..self.displayFrame .. " to " .. newdisplayFrame)
    while self.displayFrame < newdisplayFrame do
        log(4, "FF advancing game. Frame: " .. self.displayFrame)
        self:advanceFrame()
    end
    desyncLog(1, self.game.ball.velocity)
    self.confirmedFrame = newConfirmedFrame
end

function NetworkGame:calculateFrameAdvantage()
    local framesToRemote = self.inputFrame-self.confirmedFrame
    local framesRoundTrip = self.inputFrame-self.confirmedByRemoteFrame
    local frameAdvantage = framesRoundTrip - framesToRemote * 2
    log(4, "Frame advantage is " .. frameAdvantage)
    self.syncFrames = self.syncFrames - frameAdvantage * syncSmoothing / 60 -- 60 fps
    if frameAdvantage < 0 then
        if self.syncFrames < 0 then
            self.syncFrames = 0
        end
    end
end

function NetworkGame:advanceFrame()
    self.game:advanceFrame()
    self.displayFrame = self.displayFrame + 1
    self.inputFrame = self.displayFrame + self.delay
    local gameState = self.game:getState()
    self.states:push(gameState)
    if Debug and Debug.replayDebug == 1 then
        self.replay[self.displayFrame] = gameState
    end
end

function NetworkGame:remotePlayerIsDisconnected()
    return not NetworkManager:getPlayer(self.remotePlayerId) or NetworkManager:getPlayer(self.remotePlayerId).state == "disconnected"
end

function NetworkGame:sendInputs(fromFrame)
    local inputsToSend = {}
    local i = fromFrame
    while self.inputs[i] and self.inputs[i][self.player] do
        table.insert(inputsToSend, self.inputs[i][self.player]:clone())
        i = i + 1
    end
    local localInputsPacket = NetworkPackets.Inputs(
        inputsToSend,
        fromFrame,
        self.confirmedFrame
    )
    NetworkManager:send(localInputsPacket)
    log(4, "Sent inputs from " .. fromFrame .. " to " .. i-1)
    log(5, inputsToSend)
end

function NetworkGame:sendInputsAck(frame)
    NetworkManager:send(NetworkPackets.InputsAck(frame))
end

function NetworkGame:sendDisconnect()
    NetworkManager:disconnect(self.remotePlayerId)
end

function NetworkGame:handleInputPacket(packet)
    if packet.player ~= self.remotePlayerId then
        log(4, "Ignoring packet from unknown player " .. packet.player)
        log(5, packet.player,self.remotePlayerId)
        return
    end
    packet = packet.packet
    local frame = packet.startFrame
    log(4, "Got inputs for frame "..frame..": ")
    log(5, packet.inputs)
    for _, input in ipairs(packet.inputs) do
        input = Vector(input.x, input.y) -- @fixme ?
        if frame < self.confirmedFrame then
            log(4, "Received conflicting packet for frame "..frame.." but frame " .. self.confirmedFrame .. " is confirmed")
        else
            self:addInputs(frame, self.opponent, input)
        end
        frame = frame + 1
    end
    if self.confirmedByRemoteFrame < packet.ackFrame then
        self.confirmedByRemoteFrame = packet.ackFrame
    end
end

function NetworkGame:keypressed(key, scancode, isrepeat)
    if key == "escape" then
        self:sendDisconnect()
        replay.inputs = self.inputs -- replay is global
        replay.states = self.replay
    end
end

function NetworkGame:draw()
    self.game:draw()
    if self.disconnected then
        love.graphics.print("Your opponent is disconnected", 300, 300)
    end
    if Debug and Debug.showFps == 1 then
        love.graphics.print(""..tostring(love.timer.getFPS( )), 2, 2)
    end
    if Debug and Debug.netcodeDebugWidget == 1 then
        self:drawDebugWidget()
    end
end

function NetworkGame:drawDebugWidget()
    love.graphics.print(
        string.format(
            "display: %5d\nconfirm: %5d (%3d)\nremConf: %5d (%3d)\nsyncFrame: %5.2f\n",
            self.displayFrame,
            self.confirmedFrame, self.confirmedFrame-self.inputFrame,
            self.confirmedByRemoteFrame, self.confirmedByRemoteFrame-self.inputFrame,
            self.syncFrames
        ), 2, 16)
    local i = 1
    local frame = self.displayFrame - maxRollback
    while i < 100 do
        love.graphics.setColor(0.3,1,0.3)
        if frame + i >= self.displayFrame then
            love.graphics.setColor(0.9,0.7,0)
        end
        if frame + i == self.confirmedFrame then
            love.graphics.setColor(0,0.4,0)
        end
        if frame + i == self.confirmedByRemoteFrame then
            love.graphics.setColor(0.5,0.5,0.9)
        end
        if self.inputs[frame + i] then
            if self.inputs[frame + i][1] then
                love.graphics.rectangle("fill", 60 + i * 6, 10, 5, 5)
            end
            if self.inputs[frame + i][2] then
                love.graphics.rectangle("fill", 60 + i * 6, 16, 5, 5)
            end
        else
            break
        end
        i = i + 1
    end
end

return NetworkGame