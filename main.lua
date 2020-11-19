require "utils"
require "engine.debug"

local StateManager = require "lib.hump.gamestate"
local states = {
    netgame = require "netcode.network_game",
    replay = require "replay_game"
}

local aerohockeyGame = require "game"

function love.load()
    StateManager.switch(states.netgame, aerohockeyGame)
end

function love.draw()
    StateManager.draw()
end

function love.keypressed(key, scancode, isrepeat)
    StateManager.keypressed(key, scancode, isrepeat)
    if key == "r" then
        if StateManager.current().inputs then
            StateManager.switch(states.replay, require "game", StateManager.current().inputs, StateManager.current().replay)
        end
    end
end

function love.update(dt)
    StateManager.update(dt)
end
