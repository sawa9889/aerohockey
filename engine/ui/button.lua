Class = require "lib.hump.class"
UIobject = require "engine.ui.uiparents.uiobject"

-- Кнопка, умеет нажиматься и писать при этом в лог, все кнопки по хорошему должны наследоваться от этого класса и накидывать кастомные действия и картинки
Button = Class {
    __includes = UIobject,
    init = function(self, x, y, width, height, callback, tag, position)
        UIobject.init(self, x, y, width and width or 100, height and height or 50, tag, position)
        self.clickInteraction = callback
    end
}

function Button:render()
	local img = AssetManager:getImage('experimental_button')
	local width, height = img:getDimensions()
	love.graphics.draw(img, self.x, self.y, 0, self.width/width, self.height/height )
    love.graphics.setColor( 0, 0, 0, 1 )
    love.graphics.print(self.tag,self.x+self.width/5, self.y+self.height/5)
    love.graphics.setColor( 1, 1, 1, 1 )
end

function Button.defaultCallback(self)
     print(self.tag,'Clicked')
end

function Button:drawObject(x, y, angle, width, height)
	local img = AssetManager:getImage('experimental_button')
	local widthLoc, heightLoc = img:getDimensions()
	love.graphics.draw(img, x, y, 0, width/widthLoc, height/heightLoc )
    love.graphics.setColor( 0, 0, 0, 1 )
    love.graphics.print(self.tag, x + width/5, y + height/5)
    love.graphics.setColor( 1, 1, 1, 1 )
end

return Button