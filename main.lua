require "utils"
require "engine.debug"

StateManager = require "lib.hump.gamestate"
AssetManager = require "engine.asset_manager"

states = {
    menu = require "menu",
    netgame = require "netcode.network_game",
    replay = require "replay_game",
}

fonts = {
    smolPixelated = love.graphics.newFont("resource/fonts/m3x6.ttf", 16),
    sevenSegment = love.graphics.newFont("resource/fonts/7_digit_font.ttf", 115)
}

settings = require "engine.settings"

replay = {}

function love.load()
    settings:load()
    AssetManager:load("resource")
    love.keyboard.setKeyRepeat(true)
    StateManager.switch(states.menu)
end

function love.draw()
    love.graphics.setColor(1,1,1)
    StateManager.draw()
end

function love.keypressed(t)
    StateManager.keypressed(t)
    if t == "escape" then
        StateManager.switch(states.menu)
    end
end

function love.mousepressed(x, y)
    StateManager.mousepressed(x, y)
end

function love.mousereleased(x, y)
    StateManager.mousereleased(x, y)
end

function love.update(dt)
    StateManager.update(dt)
end
