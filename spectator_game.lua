local NetworkPackets = require "netcode.network_packets"
local Vector = require "lib.hump.vector"

local spectatorConfig = config.network.spectator

local SpectatorGame = {
    disconnected = false,
    inputs = {},
    frame = 1,
    confirmedFrame = 1,
    ffSpeed = config.network.spectatorFFSpeed,
    framesTillAck = spectatorConfig.framesPerAck,
    framesToAdvance = 0
}

function SpectatorGame:enter(prevState, game)
    self.isPaused = false
    self.frame = 1
    self.game = game
    self.game:init(function() return self:getGameInputs() end)
    self.startState = self.game:getState()
    self.serverPlayerId = "server"
end

function SpectatorGame:update(dt)
    NetworkManager:update(dt)
    self:recieveInputs()
    self:sendAck(self.confirmedFrame)

    if self:remotePlayerIsDisconnected() then
        if not self.disconnected then
            NetworkManager:close()
            self.disconnected = true
        end
        return
    end
    self.framesToAdvance = self.framesToAdvance + self:getFrameAdvance()
    if self.frame < self.confirmedFrame then
        while self.framesToAdvance >= 1 do
            self:advanceFrame()
            self.framesToAdvance = self.framesToAdvance - 1
        end
    end
end

function SpectatorGame:sendAck(frame)
    if self.framesTillAck > 0 then
        self.framesTillAck = self.framesTillAck - 1
        return
    end
    NetworkManager:sendTo(self.serverPlayerId, NetworkPackets.SpectatorInputsAck(frame))
    self.framesTillAck = spectatorConfig.framesPerAck
end

function SpectatorGame:recieveInputs()
    local remoteInputsPackets = NetworkManager:receive("SpectatorInputs")
    for _, packet in ipairs(remoteInputsPackets) do
        self:handleInputPacket(packet)
    end
end

function SpectatorGame:handleInputPacket(packet)
    packet = packet.packet
    local frame = packet.startFrame
    for _, input in ipairs(packet.inputs) do
        self:addInput(frame, input)
        frame = frame + 1
    end
    self.confirmedFrame = self:getConfirmedFrame()
end

function SpectatorGame:addInput(frame, input)
    self.inputs[frame] = {
        Vector(input[1].x, input[1].y),
        Vector(input[2].x, input[2].y),
    }
end

function SpectatorGame:remotePlayerIsDisconnected()
    return not NetworkManager:getPlayer("server") or NetworkManager:getPlayer("server").state == "disconnected"
end

function SpectatorGame:getConfirmedFrame()
    local frame = self.confirmedFrame
    local isConfirmed = true
    while isConfirmed do
        frame = frame + 1
        isConfirmed = self:isConfirmed(frame)
    end
    return frame - 1
end

function SpectatorGame:isConfirmed(frame)
    if self.inputs[frame] and self.inputs[frame][1] and self.inputs[frame][2] then
        return true
    else
        return false
    end 
end

function SpectatorGame:getFrameAdvance()
    local framesBehind = self.confirmedFrame - self.frame
    if framesBehind > spectatorConfig.maxDelay then
        return math.clamp(1, (framesBehind - spectatorConfig.maxDelay) * 1/spectatorConfig.smoothing, spectatorConfig.ffSpeed)
    else
        return math.clamp(0, (framesBehind / spectatorConfig.minDelay), 1)
    end
end

function SpectatorGame:advanceFrame()
    if not self.inputs[self.frame] or not self.inputs[self.frame][1] or not self.inputs[self.frame][2] then
        return
    end
    self.game:advanceFrame()
    self.frame = self.frame + 1
end

function SpectatorGame:getGameInputs()
    return self.inputs[self.frame]
end

function SpectatorGame:keypressed(key, scancode, isrepeat)
    if key == "escape" then
        replay.inputs = self.inputs -- replay is global
    end
end

function SpectatorGame:draw()
    self.game:draw()
    if self.disconnected then
        love.graphics.setColor( colors.announcerText )
        love.graphics.printf("Game Ended", 20 , love.graphics.getHeight()/3+150, love.graphics.getWidth()-40, 'center')
        love.graphics.setColor( 1, 1, 1 )
    end
    love.graphics.setFont(fonts.smolPixelated)
    if Debug and Debug.showFps == 1 then
        love.graphics.print(""..tostring(love.timer.getFPS( )), 2, 2)
    end
    if Debug and Debug.netcodeDebugWidget == 1 then
        self:drawDebugWidget()
    end
end

function SpectatorGame:drawDebugWidget()
    love.graphics.setFont(fonts.smolPixelated)
    love.graphics.print(
        string.format(
            "display: %5d\nconfirm: %5d (%3d)\nframesToAdvance: %5d\n",
            self.frame,
            self.confirmedFrame, self.confirmedFrame-self.frame,
            self.framesToAdvance
        ), 2, 16)
end

return SpectatorGame
