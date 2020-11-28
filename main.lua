require "utils"
require "engine.debug"

StateManager = require "lib.hump.gamestate"
states = {
    menu = require "menu",
    netgame = require "netcode.network_game",
    replay = require "replay_game",
}

replay = {}

function love.load()
    StateManager.switch(states.menu)
end

function love.draw()
    StateManager.draw()
end

function love.keypressed(key, scancode, isrepeat)
    StateManager.keypressed(key, scancode, isrepeat)
    if key == "escape" then
        StateManager.switch(states.menu)
    end
end

function love.update(dt)
    StateManager.update(dt)
end
