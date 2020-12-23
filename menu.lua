-- This is gamestate

NetworkManager = require "netcode.network_manager" -- yeah, global
WindowManager  = require "engine.ui.window_manager"
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
    MenuWindowManager = WindowManager(nil,nil,nil,nil, AssetManager:getImage('menu_back'))
    MenuWindowManager:registerObject("port_input", InputBox(
        x, y, 
        inputWidth, inputHeight, 
        nil, nil,
        'Port', settings:get("port")))
    MenuWindowManager:registerObject("ip_input", InputBox(
        x, y + inputHeight + inputsGap, 
        inputWidth, inputHeight, 
        nil, nil,
        'Address', settings:get("ip")))
    MenuWindowManager:registerObject("start_server_btn", Button(
        x + inputWidth + buttonsGap, y, 
        buttonWidth, buttonHeight, 
        function() 
            NetworkManager:startServer(MenuWindowManager:getObject("port_input"):getText(), 1)
            self.localPlayer = 1
        end, 
        'Start server'))
    MenuWindowManager:registerObject("connect_btn", Button(
        x + inputWidth + buttonsGap, y + (buttonHeight + inputsGap), 
        buttonWidth, buttonHeight, 
        function() 
              NetworkManager:connectTo(MenuWindowManager:getObject("ip_input"):getText(), MenuWindowManager:getObject("port_input"):getText())
              self.localPlayer = 2
        end, 
        'Start connect'))
    MenuWindowManager:registerObject("replay_btn", Button(
        x, y + (buttonHeight + inputsGap)*2, 
        buttonWidth, buttonHeight, 
        function() 
            if replay.inputs then
                StateManager.switch(states.replay, require "game", replay.inputs, replay.states)
            end
        end, 
        'Show replay'))
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
    MenuWindowManager:draw()
end

return Menu