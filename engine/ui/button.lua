Class = require "lib.hump.class"
UIobject = require "engine.ui.uiparents.uiobject"

-- Кнопка, умеет нажиматься и писать при этом в лог, все кнопки по хорошему должны наследоваться от этого класса и накидывать кастомные действия и картинки
Button = Class {
    __includes = UIobject,
    init = function(self, x, y, width, height, callback, tag)
        UIobject.init(self, x, y, width and width or 100, height and height or 50, tag)
        self.clickInteraction = callback
    end
}

function Button:render()
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height )
    love.graphics.print(self.tag,self.x+self.width/5, self.y+self.height/5)
end

function Button.defaultCallback(self)
     print(self.tag,'Clicked')
end

return Button