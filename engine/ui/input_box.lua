Class = require "lib.hump.class"
UIobject = require "engine.ui.uiparents.uiobject"
local utf8 = require("utf8")

-- Кнопка, умеет нажиматься и писать при этом в лог, все кнопки по хорошему должны наследоваться от этого класса и накидывать кастомные действия и картинки
InputBox = Class {
	__includes = UIobject,
	init = function(self, x, y, width, height, parameters)
		UIobject.init(self, x, y, width and width or 100, height and height or 50, parameters.tag, parameters.position)
		self.startClickInteraction = parameters.click and parameters.click or self.defaultClick
		self.misClickInteraction = parameters.unclick and parameters.unclick or self.defaultUnclick
		self.text = parameters.defaultText or ''
	end
}

function InputBox:render()
	local img = AssetManager:getImage('field')
	local width, height = img:getDimensions()
	love.graphics.draw(img, self.x, self.y, 0, self.width/width, self.height/height )
    love.graphics.setColor( 0, 0, 0, 1 )
	love.graphics.print(self.tag, self.x - self.width/3, self.y + self.height/5)
	love.graphics.print(self.text,self.x + self.width/5, self.y + self.height/5)
    love.graphics.setColor( 1, 1, 1, 1 )
end

function InputBox:drawObject(x, y, angle, width, height, simbolsInLine)
	local simbolsInLine = simbolsInLine and simbolsInLine or 16
	local img = AssetManager:getImage('field')
	local widthLoc, heightLoc = img:getDimensions()
	love.graphics.draw(img, x, y, 0, width/widthLoc, height/heightLoc )
    love.graphics.setColor( 0, 0, 0, 1 )

    local currentFont = love.graphics.getFont( )

    local outsideFontSize = height*0.8
    local outsideFont = love.graphics.newFont("resource/fonts/m3x6.ttf", outsideFontSize)
    local insideTextWidth, outsideTextWidth = width*0.8, outsideFont:getWidth(self.tag)
    
    local insideFontSize = 4*insideTextWidth/simbolsInLine
    local insideFont  = love.graphics.newFont("resource/fonts/m3x6.ttf", insideFontSize )

    love.graphics.setFont(outsideFont)
    love.graphics.print(self.tag,  x - outsideTextWidth, y + height/2 - outsideFont:getHeight()/2)

    love.graphics.setFont(insideFont)
	love.graphics.print(self.text, x + (width - insideTextWidth)/2, y + height/2 - insideFont:getHeight()/2)

    love.graphics.setFont(currentFont)
    love.graphics.setColor( 1, 1, 1, 1 )
end

function InputBox.defaultClick(self)
	if not self.focused then
		self.focused = true
		print('Focused')
	end
end

function InputBox.defaultUnclick(self)
	if self.focused then
		self.focused = false
	end
end

function InputBox:getText()
	return self.text
end

function InputBox:keypressed( key)
	if self.focused then
		if self.serviceButtonPressed and (self.serviceButton == 'lctrl' or self.serviceButton == 'rctrl') and key == 'backspace' then
			self.text = ''
		elseif key == "backspace" then
			local byteoffset = utf8.offset(self.text, -1)
	 
			if byteoffset then
				self.text = string.sub(self.text, 1, byteoffset - 1)
			end
		elseif self.serviceButtonPressed and (self.serviceButton == 'lctrl' or self.serviceButton == 'rctrl') and key == 'v' then
			self.text = love.system.getClipboardText()
		elseif self.serviceButtonPressed and (self.serviceButton == 'lctrl' or self.serviceButton == 'rctrl') and key == 'c' then
			love.system.setClipboardText(self.text)
		elseif string.len(key) == 1 then
			if self.serviceButtonPressed then
				self.serviceButtonPressed = false
				self.serviceButton = ''
			else
				self.text = self.text .. key
			end
		else 
			self.serviceButtonPressed = true
			self.serviceButton = key
		end
	end
end

return InputBox