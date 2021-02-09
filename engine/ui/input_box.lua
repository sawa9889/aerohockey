Class = require "lib.hump.class"
UIobject = require "engine.ui.uiparents.uiobject"
local utf8 = require("utf8")

-- Кнопка, умеет нажиматься и писать при этом в лог, все кнопки по хорошему должны наследоваться от этого класса и накидывать кастомные действия и картинки
InputBox = Class {
	__includes = UIobject,
	init = function(self, parent, parameters)
		UIobject.init(self, parent, parameters)


        self.clickInteraction['startClickInteraction'] =
        {
            condition = function (object, x, y) return object:getCollision(x, y)  end,
            func =  function (obj, x, y)
            			obj.focused = true
                    end
        }

        self.clickInteraction['mousprmisClickInteractionessed'] =
        {
            condition = function (object, x, y) return not object:getCollision(x, y)  end,
            func =  function (obj, x, y)
            			obj.focused = false
                    end
        }

        self:registerObject('Field_Name', 
                               { left = -self.width*0.55, up = self.height*0.1}, 
                               Label(self, {tag = 'test_label1', text = self.tag, width = self.width*0.5, height = self.height*0.8 }))
        self:registerObject('Entered_text', 
                               { left = self.width*0.1, up = self.height*0.1}, 
                               Label(self, {tag = 'test_label2', text = nvl(parameters.defaultText, ''), width = self.width*0.8, height = self.height*0.8 }))

        self.keyInteraction['keyInput'] = 
        {
            condition = function (object, x, y) 
                            return self.focused
                        end,
            func =  function (obj, key)
            			local text = obj:getText()
                        if obj.serviceButtonPressed and (obj.serviceButton == 'lctrl' or obj.serviceButton == 'rctrl') and key == 'backspace' then
							obj:setText('')
						elseif key == "backspace" then
							local byteoffset = utf8.offset(text, -1)
					 
							if byteoffset then
								obj:setText(string.sub(text, 1, byteoffset - 1))
							end
						elseif obj.serviceButtonPressed and (obj.serviceButton == 'lctrl' or obj.serviceButton == 'rctrl') and key == 'v' then
							obj:setText(love.system.getClipboardText())
						elseif obj.serviceButtonPressed and (obj.serviceButton == 'lctrl' or obj.serviceButton == 'rctrl') and key == 'c' then
							love.system.setClipboardText(text)
						elseif string.len(key) == 1 then
							if obj.serviceButtonPressed then
								obj.serviceButtonPressed = false
								obj.serviceButton = ''
							else
								obj:setText(text .. key)
							end
						else 
							obj.serviceButtonPressed = true
							obj.serviceButton = key
						end
                    end
        }
		
	end
}

function InputBox:render()
end

function InputBox:getText()
	return self.objects['Entered_text'].object.text
end

function InputBox:setText(text)
	self.objects['Entered_text'].object.text = text
end

return InputBox