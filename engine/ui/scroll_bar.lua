Class = require "lib.hump.class"
UIobject = require "engine.ui.uiparents.uiobject"

-- Просто лейбл, для удобства выписывания всякого и для единообразности объектов в UI
ScrollBar = Class {
    __includes = UIobject,
    init = function(self, parent, parameters)
        UIobject.init(self, parent, parameters)
        self.text = parameters.text
        self.targetObject = parameters.targetObject
        self:registerObject("up_button", 
                             {}, 
                             Button(self, {  
                                tag = 'up', 
                                width = self.width, 
                                height = self.height*0.1, 
                                background = AssetManager:getImage('experimental_button'),
                                callback = function(obj, x, y) obj.targetObject:moveObjects(-50) end
                            }))
        self:registerObject("down_button", 
                             {down = self.height*0.1}, 
                             Button(self, {  
                                tag = 'Down', 
                                width = self.width, 
                                height = self.height*0.1,
                                background = AssetManager:getImage('experimental_button'),
                                callback = function(obj, x, y) obj.targetObject:moveObjects(50) end
                            }))

        local cnt = count(self.targetObject.objects, function() return true end)
        local koef2 = self.targetObject.rows / cnt > 1 and 1 or self.targetObject.rows / cnt
        local height = self.height * 0.8

        self:registerObject("scroll_button", 
                             {up = self.height * 0.1}, 
                             Button(self, {  
                                tag = '', 
                                width = self.width, 
                                height = height * koef2 , 
                                background = AssetManager:getImage('experimental_button'),
                                callback = function(obj, x, y) self.parent.activePage = "Main_Menu" end
                            }))

        self.wheelInteraction['scrollList'] =
        {
            condition = function (object, x, y) return true end,
            func =  function (obj, x, y)
        				local koef2 = obj.targetObject.rows / cnt > 1 and 1 or obj.targetObject.rows / cnt
            			local cnt = count(obj.targetObject.objects, function() return true end)
            			obj.objects['scroll_button'].position.y = obj.height*0.1 + obj.height*0.8 * koef2 * - (obj.targetObject.firctCellY/(cnt * (obj.targetObject.cellHeight+obj.targetObject.margin))) 
                    end
        }
    end
}

function ScrollBar:render()
end

return ScrollBar