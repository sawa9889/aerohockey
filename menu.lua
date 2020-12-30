-- This is gamestate

NetworkManager = require "netcode.network_manager" -- yeah, global
WindowManager  = require "engine.ui.window_manager"
MainMenuContainer = require "main_menu"
Button         = require "engine.ui.button"
InputBox       = require "engine.ui.input_box"

local aerohockeyGame = require "game"

local Menu = {
    localPlayer = 1,
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
end

function Menu:update(dt)
    NetworkManager:update(dt)
    MenuWindowManager:update(dt)
    if NetworkManager:connectedPlayersNum() == 1 then
        self:updateSettings()
        StateManager.switch(states.netgame, aerohockeyGame, self.localPlayer)
    end
end

function Menu:updateSettings()
    settings:set("ip", MenuWindowManager:getObject("ip_input"):getText())
    settings:set("port", MenuWindowManager:getObject("port_input"):getText())
    settings:save()
end

function Menu:keypressed(t)
    MenuWindowManager:keypressed(t)
end

function Menu:mousepressed(x, y)
    MenuWindowManager:mousepressed(x, y)
end


function Menu:draw()
    love.graphics.setColor( 0.25, 0.35, 1, 1 )
    love.graphics.rectangle( 'fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight() )
    love.graphics.setColor( 1, 1, 1, 1 )
    MenuWindowManager:draw()
end

return Menu