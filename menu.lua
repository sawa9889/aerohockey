-- This is gamestate

NetworkManager = require "netcode.network_manager" -- yeah, global

local aerohockeyGame = require "game"

local Menu = {
    localPlayer = 1,
}

function Menu:enter(prevState, game)
end

function Menu:update(dt)
    NetworkManager:update(dt)
    if NetworkManager:connectedPlayersNum() == 1 then
        StateManager.switch(states.netgame, aerohockeyGame, self.localPlayer)
    end
end

function Menu:keypressed(key, scancode, isrepeat)
    if key == "1" then
        NetworkManager:startServer(12345, 1)
        self.localPlayer = 1
    end
    if key == "2" then
        NetworkManager:connectTo("127.0.0.1", 12345)
        self.localPlayer = 2
    end
    if key == "r" then
        if replay.inputs then
            StateManager.switch(states.replay, require "game", replay.inputs, replay.states)
        end
    end
end

function Menu:draw()
    love.graphics.print("Press \"1\" to start server\nPress \"2\" to connect to game\nPress \"R\" to load a replay")
end

return Menu