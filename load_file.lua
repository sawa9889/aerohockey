Class = require "lib.hump.class"
UiObject = require "engine.ui.uiparents.uiobject"
Button         = require "engine.ui.button"
InputBox       = require "engine.ui.input_box"
FilesList      = require "files_list"

LoadFileContainer = Class {
    __includes = UiObject,
    init = function(self, parent)
        UiObject.init(self, 0, 0, love.graphics.getWidth(), love.graphics.getHeight(), 'Load File')
        self.parent = parent
        self.windowManager = WindowManager( self.x, self.y, self.width, self.height )
        self.windowManager:registerObject("Files list", FilesList(
                                          love.graphics.getWidth()*0.1, love.graphics.getHeight()*0.1, 
                                          love.graphics.getWidth()*0.8, love.graphics.getHeight()*0.8, 
                                          love.graphics.getHeight()*0.01, '%appdata%/LOVE/'))
        self.windowManager:registerObject("return_btn", Button(
            love.graphics.getWidth()*0.1, love.graphics.getHeight()*0.8, 
            love.graphics.getWidth()*0.1, love.graphics.getHeight()*0.1, 
            {
                callback =  function() 
                                self.parent.activePage = "Main_Menu"
                            end,
                tag = 'Return',
                position = 'relative',
            }))
    end
}

function LoadFileContainer:keypressed(t)
    self.windowManager:keypressed(t)
end

function LoadFileContainer:mousepressed(x, y)
    self.windowManager:mousepressed(x, y)
end

function LoadFileContainer:wheelmoved(x, y)
    self.windowManager:wheelmoved(x, y)
end

function LoadFileContainer:render()
    self:drawBoxAroundObject({r = 0, g = 0, b = 0}, love.graphics.getWidth()/150)
    self.windowManager:draw()
end

function LoadFileContainer:update(dt)
    self.windowManager:update(dt)
end

return LoadFileContainer