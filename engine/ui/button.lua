Class = require "lib.hump.class"
UIobject = require "engine.ui.uiparents.uiobject"

-- Кнопка, умеет нажиматься и писать при этом в лог, все кнопки по хорошему должны наследоваться от этого класса и накидывать кастомные действия и картинки
Button = Class {
    __includes = UIobject,
    init = function(self, x, y, width, height, parameters)
        UIobject.init(self, x, y, width and width or 100, height and height or 50, parameters.tag, parameters.position)
        self.startClickInteraction = parameters.callback
    end
}

function Button:render()
	local img = AssetManager:getImage('experimental_button')
	local width, height = img:getDimensions()
	love.graphics.draw(img, self.x, self.y, 0, self.width/width, self.height/height )
    love.graphics.setColor( 0, 0, 0, 1 )

    local insideTextWidth = width*0.6
    local insideFontSize = 4*insideTextWidth/#self.tag
    local insideFont  = love.graphics.newFont("resource/fonts/m3x6.ttf", insideFontSize )

    love.graphics.setFont(insideFont)
    love.graphics.print(self.tag, x + (width - insideTextWidth)/2, y + height/2 - insideFont:getHeight()/2)

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

    local insideFontSize = height*0.6
    local insideFont  = love.graphics.newFont("resource/fonts/m3x6.ttf", insideFontSize )
    local insideTextWidth = insideFont:getWidth(self.tag)

    love.graphics.setFont(insideFont)
    love.graphics.print(self.tag, x + (width - insideTextWidth)/2, y + height/2 - insideFont:getHeight()/2)

    love.graphics.setColor( 1, 1, 1, 1 )
end

return Button