require "utils"
require "engine.debug"

local StateManager = require "lib.hump.gamestate"
local states = {
    netgame = require "netcode.network_game"
}

local aerohockeyGame = require "game"

function love.load()
    StateManager.switch(states.netgame, aerohockeyGame)
end

function love.draw()
    StateManager.draw()
end

function love.update(dt)
    StateManager.update(dt)
end
