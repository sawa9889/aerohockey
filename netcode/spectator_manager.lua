local NetworkPackets = require "netcode.network_packets"

local SpectatorManager = {}

function SpectatorManager:init(netGame, networkManager)
    self.networkGame = netGame
    self.networkManager = networkManager
    self.spectators = {}
    self.activePlayer = self.networkGame:getActivePlayerId()
    self.ffMaxSpeed = config.network.spectatorFFSpeed
    self.maxInptsPerPacket = config.network.maxInputsPerPacket
    return self
end

function SpectatorManager:addSpectator(id)
    self.spectators[id] = {
        playerId = id,
        ackFrame = 1
    }
end

function SpectatorManager:deleteSpectator(id)
    self.spectators[id] = nil
end

function SpectatorManager:update(dt)
    local players = self.networkManager:getPlayers()
    for playerId, player in pairs(players) do
        if playerId ~= self.activePlayer and player.state == "connected" and not self.spectators[playerId] then
            self:addSpectator(playerId)
            self.networkManager:sendTo(playerId, NetworkPackets.StartGame("spectator"))
        end
        if self.spectators[playerId] and player.state == "disconnected" then
            self.deleteSpectator(playerId)
        end
    end

    local ackPackets = self.networkManager:receive("SpectatorInputsAck")
    for _, ackPacket in pairs(ackPackets) do
        vardump(ackPacket)
        self:sendInputs(ackPacket.player, ackPacket.packet.ackFrame)
    end
end

function SpectatorManager:sendInputs(playerId, fromFrame)
    local ackFrame = self.spectators[playerId].ackFrame
    local confirmedFrame = self.networkGame:getConfirmedFrame()
    local framesToSend = math.clamp(0, confirmedFrame - ackFrame, self.maxInptsPerPacket)
    local inputs = self.networkGame:getInputs(fromFrame, framesToSend)
    vardump(playerId, inputs, fromFrame, confirmedFrame)
    self.networkManager:sendTo(playerId, NetworkPackets.SpectatorInputs(
        inputs,
        fromFrame,
        confirmedFrame
    ))
end

return SpectatorManager
