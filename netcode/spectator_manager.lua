local SpectatorManager = {}

function SpectatorManager:init(netGame, networkManager)
    self.networkGame = netGame
    self.networkManager = networkManager
    self.spectators = {}
    self.ffMaxSpeed = config.network.spectatorFFSpeed
    self.maxInptsPerPacket = config.network.maxInptsPerPacket
    return self
end

function SpectatorManager:getNewSpectator(id)
    return {
        playerId = id,
        ackFrame = 1
    }
end

function SpectatorManager:update(dt)
    -- get all spectators from networkManager
        -- if this is new spectator - save
        -- if this is disconnected spectator - delete them
    -- for each spectator
        -- get all ack packets
        -- if there are acks, get last ack frame
        -- send max inputs in spectator packet
end

function SpectatorManager:sendInputs(playerId, fromFrame)
    local ackFrame = self.spectators[playerId].ackFrame
    local confirmedFrame = self.networkGame:getConfirmedFrame()
    local framesToSend = math.clamp(0, confirmedFrame - ackFrame, self.maxInptsPerPacket)
    local inputs = self.networkGame:getInputs(fromFrame, framesToSend)
    self.networkManager:sendTo(playerId, NetworkPackets.SpectatorInputs(
        inputs,
        fromFrame,
        self.confirmedFrame
    ))
end

return function () return SpectatorManager:init() end
