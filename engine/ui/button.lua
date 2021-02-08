Class = require "lib.hump.class"
UIobject = require "engine.ui.uiparents.uiobject"

-- Кнопка, умеет нажиматься и писать при этом в лог, все кнопки по хорошему должны наследоваться от этого класса и накидывать кастомные действия и картинки
Button = Class {
    __includes = UIobject,
    init = function(self, parent, parameters)
        UIobject.init(self, parent, parameters)
        self.clickInteraction['click'] = 
        {
            condition = function (object, x, y) 
                            local screenX, screenY = love.graphics.inverseTransformPoint( x, y )
                            print(object.tag,'Clicked', x, y, screenX, screenY, object:getCollision(x, y), object:getCollision(screenX, screenY)) 
                            return object:getCollision(x, y) 
                        end,
            func =  function (obj, x, y)
                        
                    end
        }
        self:registerNewObject('Label', { align = 'center' }, {tag = 'test_label', text = self.tag, width = self.width*0.8, height = self.height*0.8 } , self)
    end
}

function Button.defaultCallback(self)
     print(self.tag,'Clicked')
end

return Button