require "utils"
require "engine.debug"

StateManager = require "lib.hump.gamestate"
AssetManager = require "engine.asset_manager"

SoundData = require "game.sound_data"
SoundManager = require "engine.sound_manager" (SoundData)

NetworkManager = require "netcode.network_manager" -- yeah, global

states = {
    menu = require "menu",
    connectingState = require "connecting_state",
    netgame = require "netcode.network_game",
    spectatorGame = require "spectator_game",
    replay = require "replay_game",
}

fonts = {
    smolPixelated = love.graphics.newFont("resource/fonts/m3x6.ttf", 16),
    sevenSegment = love.graphics.newFont("resource/fonts/7_digit_font.ttf", 115)
}

colors = {
    announcerText = { 1, 0.3, 0, 1 },
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

function love.wheelmoved(x, y)
    StateManager.wheelmoved(x, y)
end

function love.update(dt)
    StateManager.update(dt)
end
