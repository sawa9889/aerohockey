Class = require "lib.hump.class"
UiObject = require "engine.ui.uiparents.uiobject"
-- Пример ноды для Контейнеров объектов, тут необходимо задать шаблон всех объектов, по которому будет строиться каждый элемент
-- Структура своя собственная, главные требования: 
-- 1) Быть любым UIObject-ом, чтобы можно было с ним взаимодействовать через WindowManager и 
-- 2) иметь функцию пересборки, чтобы под экраны подстраиваться

Node = Class {
    __includes = UiObject,
    init = function(self, callback, tag)
        UiObject.init(self, 0, 0, 0, 0, tag)
        self.startClickInteraction = callback
    end
}
-- Функция пересборки, смысл которой заключается в изменении Ноды под новые требования, например просто сжатие или убирание не влезающих объектов
function Node:refresh(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.displayed = true
end

function Node:render()
    if self.displayed then
        local scaleX = love.graphics.getWidth()/self.width
        local scaleY = love.graphics.getHeight()/self.height
        love.graphics.setColor( 0, 0, 0, 1 )
        love.graphics.rectangle("line", self.x, self.y, self.width, self.height )
        love.graphics.setColor( 1, 1, 1, 1 )
        love.graphics.print(self.tag, self.x + 10 * scaleX, self.y, 0)
    end
end

function Node:hide()
    self.displayed = false
end

return Node