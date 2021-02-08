-- This is a gamestate

local aerohockeyGame = require "game"

local ConnectingState = {}

function ConnectingState:enter(prevState, connectionParams)
    self.connectionParams = connectionParams
    if connectionParams.isServer then
        NetworkManager:startServer(connectionParams.port, config.network.maxRemotePlayers)
    else
        NetworkManager:connectTo(connectionParams.ip, connectionParams.port)
    end
    self:updateSettings()
end

function ConnectingState:update(dt)
    NetworkManager:update(dt)

    if NetworkManager:connectedPlayersNum() > 0 then
        self:updateSettings()
        settings:save()
        if NetworkManager:getRole() == "server" then
            StateManager.switch(states.netgame, aerohockeyGame, 1)
        else
            local startGamePackets = NetworkManager:receive("StartGame")
            for _, startPacket in ipairs(startGamePackets) do
                if startPacket.packet.playerType == "player" then
                    StateManager.switch(states.netgame, aerohockeyGame, 2)
                end
                if startPacket.packet.playerType == "spectator" then
                    StateManager.switch(states.spectatorGame, aerohockeyGame)
                end
            end
        end
    end
end

function ConnectingState:updateSettings()
    settings:set("ip", self.connectionParams.ip)
    settings:set("port", self.connectionParams.port)
end

function ConnectingState:keypressed(key)
    if key == "escape" then
        NetworkManager:close()
    end
end

function ConnectingState:draw()
    -- draw "Connecting..." in the middle of the screen
end

return ConnectingState
