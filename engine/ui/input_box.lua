Class = require "lib.hump.class"
UIobject = require "engine.ui.uiparents.uiobject"
local utf8 = require("utf8")

-- Кнопка, умеет нажиматься и писать при этом в лог, все кнопки по хорошему должны наследоваться от этого класса и накидывать кастомные действия и картинки
InputBox = Class {
	__includes = UIobject,
	init = function(self, x, y, width, height, click, unclick, tag)
		UIobject.init(self, x, y, width and width or 100, height and height or 50, tag)
		self.clickInteraction = click and click or self.defaultClick
		self.unclickInteraction = unclick and unclick or self.defaultUnclick
		self.text = ''
	end
}

function InputBox:render()
	love.graphics.rectangle("line", self.x, self.y, self.width, self.height )
	love.graphics.print(self.tag,self.x - self.width/3, self.y + self.height/5)
	love.graphics.print(self.text,self.x + self.width/5, self.y + self.height/5)
end

function InputBox.defaultClick(self)
	if not self.focused then
		self.focused = true
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

function InputBox.keypress(key, self)
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