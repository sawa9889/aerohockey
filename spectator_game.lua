local NetworkPackets = require "netcode.network_packets"
local Vector = require "lib.hump.vector"

local SpectatorGame = {
    isPaused = true,
    inputs = {},
    frame = 1,
    confirmedFrame = 1,
    ffSpeed = config.network.spectatorFFSpeed
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
    -- if not recieved inputs for n seconds - send ack again
    self.isPaused = self.frame >= self.confirmedFrame
    if not self.isPaused then
        if self.frame < self.confirmedFrame then
            local i = math.min(self.ffSpeed, self.confirmedFrame - self.frame) -- and divide that to some smoothing
            while i > 0 do
                self:advanceFrame()
                i = i - 1
            end
        end
        self:advanceFrame()
    end
end

function SpectatorGame:sendAck(frame)
    NetworkManager:sendTo(self.serverPlayerId, NetworkPackets.SpectatorInputsAck(frame))
end

function SpectatorGame:recieveInputs()
    local remoteInputsPackets = NetworkManager:receive("SpectatorInputs")
    for _, packet in ipairs(remoteInputsPackets) do
        self:handleInputPacket(packet)
    end
end

function SpectatorGame:handleInputPacket(packet)
    packet = packet.packet
    vardump(packet)
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
end

function SpectatorGame:draw()
    self.game:draw()
    love.graphics.setFont(fonts.smolPixelated)
    if Debug and Debug.showFps == 1 then
        love.graphics.print(""..tostring(love.timer.getFPS( )), 2, 2)
    end
    -- debug widget as in network game
end

return SpectatorGame
