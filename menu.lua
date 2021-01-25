-- This is gamestate

WindowManager  = require "engine.ui.window_manager"
MainMenuContainer = require "main_menu"
LoadFileContainer = require "load_file"
Button         = require "engine.ui.button"
InputBox       = require "engine.ui.input_box"

local Menu = {
    localPlayer = 1,
    windowManager = nil
}

local MenuWindowManager

function Menu:enter(prevState, game)
    local scale = 3
    love.graphics.setFont(love.graphics.newFont("resource/fonts/m3x6.ttf", 16*scale))
    local buttonHeight, buttonWidth = 25*scale, 100*scale
    local inputHeight, inputWidth = 25*scale, 100*scale
    local buttonsGap, inputsGap = 25*scale, 10*scale
    local x, y = love.graphics.getWidth()/2 - buttonWidth, love.graphics.getHeight()/2 - 2*buttonHeight
    MenuWindowManager = WindowManager()
    MenuWindowManager:registerObject("Main_Menu", MainMenuContainer(MenuWindowManager))
    MenuWindowManager:registerObject("Load_Menu", LoadFileContainer(MenuWindowManager))
    MenuWindowManager.activePage = 'Main_Menu'
end

function Menu:update(dt)
    NetworkManager:update(dt)
    MenuWindowManager:getObject(MenuWindowManager.activePage):update(dt)
end

function Menu:keypressed(t)
    if MenuWindowManager:getObject(MenuWindowManager.activePage).keypressed then
        MenuWindowManager:getObject(MenuWindowManager.activePage):keypressed(t)
    end
end

function Menu:mousepressed(x, y)
    if MenuWindowManager:getObject(MenuWindowManager.activePage).mousepressed then
        MenuWindowManager:getObject(MenuWindowManager.activePage):mousepressed(x, y)
    end
end

function Menu:wheelmoved(x, y)
    if MenuWindowManager:getObject(MenuWindowManager.activePage).wheelmoved then
        MenuWindowManager:getObject(MenuWindowManager.activePage):wheelmoved(x, y)
    end
end

function Menu:draw()
    love.graphics.setColor( 0.25, 0.35, 1, 1 )
    love.graphics.rectangle( 'fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight() )
    love.graphics.setColor( 1, 1, 1, 1 )
    MenuWindowManager:getObject(MenuWindowManager.activePage):draw()
end

return Menu