require "utils"
require "engine.debug"

StateManager = require "lib.hump.gamestate"
states = {
    menu = require "menu",
    netgame = require "netcode.network_game",
    replay = require "replay_game",
}

love.graphics.setFont(love.graphics.newFont("resource/fonts/m3x6.ttf", 16))

replay = {}

function love.load()
    love.keyboard.setKeyRepeat(true)
    StateManager.switch(states.menu)
end

function love.draw()
    love.graphics.setColor(1,1,1)
    StateManager.draw()
end

-- function love.keypressed(key, scancode, isrepeat)
--     StateManager.keypressed(key, scancode, isrepeat)
-- end

-- function love.textinput(t)
--     StateManager.keypressed(t)
--     if t == "escape" then
--         StateManager.switch(states.menu)
--     end
-- end

function love.keypressed(key, scancode, isrepeat)
    StateManager.keypressed(key, scancode, isrepeat)
    if key == "escape" then
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
