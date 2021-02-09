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
                            return object:getCollision(x, y) 
                        end,
            func =  parameters.callback
        }
        self:registerObject('Label', 
                               { left = self.width*0.1, up = self.height*0.1}, 
                               Label(self, {tag = 'test_button_label', text = self.tag, width = self.width*0.8, height = self.height*0.8 }))
    end
}


return Button