-- This is gamestate

UIobject  = require "engine.ui.uiparents.uiobject"
-- MainMenuContainer = require "main_menu"
-- LoadFileContainer = require "load_file"
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
    MenuWindowManager = UIobject(nil, {tag = 'Main menu', columns = 4, rows = 4, margin = 10})
    -- MenuWindowManager:registerObject("test_inner_table", 
    --                                  {row = 2, column = 2}, 
    --                                  {  
    --                                     tag = 'Test1', 
    --                                     columns = 1, 
    --                                     rows = 1, 
    --                                     margin = 0, 
    --                                     width = 200, 
    --                                     height = 50, 
    --                                     background = AssetManager:getImage('experimental_button')
    --                                 },
    --                                  MenuWindowManager)
    MenuWindowManager:registerObject("test_inner_table", 
                                     {row = 2, column = 2}, 
                                     Button(MenuWindowManager, {  
                                        tag = 'Test1', 
                                        width = 200, 
                                        height = 50, 
                                        background = AssetManager:getImage('experimental_button')
                                    }))

    -- MenuWindowManager:registerObject("Main_Menu", MainMenuContainer(MenuWindowManager))
    -- MenuWindowManager:registerObject("Load_Menu", LoadFileContainer(MenuWindowManager))
    MenuWindowManager.activePage = 'Main_Menu'
end

function Menu:update(dt)
    NetworkManager:update(dt)
    MenuWindowManager:update(dt)
end

function Menu:keypressed(t)
    MenuWindowManager:keypress(t)
end

function Menu:mousepressed(x, y)
    print(x,y )
    MenuWindowManager:mousepressed(x, y)
end

function Menu:wheelmoved(x, y)
    MenuWindowManager:wheelmoved(x, y)
end

function Menu:draw()
    love.graphics.setColor( 0.25, 0.35, 1, 1 )
    love.graphics.rectangle( 'fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight() )
    love.graphics.setColor( 1, 1, 1, 1 )
    MenuWindowManager:draw()
end

return Menu