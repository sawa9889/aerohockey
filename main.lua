local StateManager = require "lib.hump.gamestate"

local states = {
    --lobby = require "game.states.lobby"
    game = require "game.states.game"
}

function love.load()
    StateManager.switch(states.game)
end

function love.draw()
    StateManager.draw()
end

function love.update(dt)
    StateManager.update(dt)
end

function love.keypressed(key)
end
