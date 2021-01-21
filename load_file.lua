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
									      love.graphics.getWidth()*0.8, love.graphics.getHeight()*0.7, 
									      love.graphics.getHeight()*0.01, 'resource/test'))
    end
}

function LoadFileContainer:keypressed(t)
    self.windowManager:keypressed(t)
end

function LoadFileContainer:mousepressed(x, y)
    self.windowManager:mousepressed(x, y)
end
-- Указан отдельный объект чтобы логика указанная в Draw была сквозной, а опциональная была в render
function LoadFileContainer:render()
    love.graphics.setColor( 0, 0, 0, 1 )
    love.graphics.setLineWidth( love.graphics.getWidth()/150 )
    love.graphics.rectangle( 'line', self.x, self.y, self.width, self.height )
    love.graphics.setLineWidth( 1 )
    love.graphics.setColor( 1, 1, 1, 1 )
    self.windowManager:draw()
end

function LoadFileContainer:update(dt)
    self.windowManager:update(dt)
end

return LoadFileContainer