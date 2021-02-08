Class = require "lib.hump.class"
-- Абстрактный класс любого атомарного объекта для UI, сожержит зародыши умений объектов, такие как DragAndDrop и Кликабельность, также позиционирование
-- 
UIobject = Class {
    init = function(self, parent, parameters)

        self.parent = parent
        self.tag = parameters.tag

        self.clickInteraction   = nvl(parameters.clickInteraction, {})
        self.releaseInteraction = nvl(parameters.releaseInteraction, {})
        self.wheelInteraction   = nvl(parameters.wheelInteraction, {})
        self.keyInteraction     = nvl(parameters.keyInteraction, {})


        self.clickInteraction['mouspressed'] =
        {
            condition = function (object, x, y) return true end,
            func =  function (obj, x, y)
                        for ind, object in pairs(obj.objects) do
                            for funcName, callback in pairs(object.object.clickInteraction) do
                                if callback.condition(object, x, y) then
                                    callback.func(object, x, y)
                                end
                            end
                        end
                    end
        }
        self.releaseInteraction['mousereleased'] =
        {
            condition = function (object, x, y) return true end,
            func =  function (obj, x, y)
                        for ind, object in pairs(obj.objects) do
                            for funcName, callback in pairs(object.object.releaseInteractions) do
                                if callback.condition(object, x, y) then
                                    callback.func(object, x, y)
                                end
                            end
                        end
                    end
        }
        self.wheelInteraction['wheelmoved'] =
        {
            condition = function (object, x, y) return true end,
            func =  function (obj, x, y)
                        for ind, object in pairs(obj.objects) do
                            for funcName, callback in pairs(object.object.wheelInteractions) do
                                if callback.condition(object, x, y) then
                                    callback.func(object, x, y)
                                end
                            end
                        end
                    end
        }
        self.keyInteraction['keypressed'] =
        {
            condition = function (object, key) return true end,
            func =  function (obj, key)
                        for ind, object in pairs(obj.objects) do
                            for funcName, callback in pairs(object.object.keyInteractions) do
                                if callback.condition(object, key) then
                                    callback.func(object, key)
                                end
                            end
                        end
                    end
        }

        self.x, self.y = 0, 0
        self.width = nvl(parameters.width, love.graphics.getWidth())
        self.height = nvl(parameters.height, love.graphics.getHeight())

        self.objects = nvl(parameters.objects, {})
        self.background = parameters.background

        self.columns = nvl(parameters.columns, 1)
        self.rows = nvl(parameters.rows, 1)
        self.margin = nvl(parameters.margin, 10)

        self.calculatePositionMethods = {
                                            one = self.calculateRelationalPosition,
                                            two = self.calculatePositionWithAlign,
                                            three = self.calculatePositionInTable,
                                            four = self.calculateFixedPosition,
                                        }
    end
}

-- Регистрация объекта в окошке, для его отображения и считывания действий
function UIobject:registerObject(index, position, parameters, parent)
    local object = UIobject(parent, parameters)
    self:calculateCoordinatesAndWriteToObject(position)
    self.objects[index] = { 
                            position = position, 
                            parameters = parameters,
                            object = object,
                          }
end

-- Всем объектам надо уметь понимать случилась ли коллизия, причем не важно с мышкой или чем-то ещё
function UIobject:getCollision(x, y)
    return 	self.x < x and
            (self.x + self.width) > x and
            self.y < y and
            (self.y + self.height) > y
end

-- Указан отдельный объект чтобы логика указанная в Draw была сквозной, а опциональная была в render
function UIobject:changePosition(x, y)
    self.x, self.y = x, y
end

function UIobject:calculateFixedPosition(position, x, y)
    x = nvl(position.fixedX, x)
    y = nvl(position.fixedY, y)
    print('calculateFixedPosition', x, y)
    return x, y
end

function UIobject:calculateRelationalPosition(position, x, y)
    if position.left or position.right or position.up or position.down then
        x = self.x + nvl(position.left,0) + (self.width - nvl(position.right, self.width))
        y = self.y + nvl(position.up,0) + (self.height - nvl(position.down, self.height))
    end
    print('calculateRelationalPosition', x, y)
    return x, y
end

function UIobject:calculatePositionInTable(position, x, y)
    if position.row and position.column then
        local ind = position.row*self.columns + position.column
        local cell_width = (self.width - self.margin*(self.columns-1))/self.columns
        local cell_height = (self.height - self.margin*(self.rows-1))/self.rows
        x = (cell_width + self.margin) * (ind % self.columns)
        y = (cell_height + self.margin) * (ind/self.columns - (ind / self.columns)%1)
    end
    print('calculatePositionInTable', x, y)
    return x, y
end

function UIobject:calculatePositionWithAlign(position, x, y)
    if position.align == 'center' then
        x = self.width/2
        y = self.height/2
    elseif  position.align == 'right' then
        x = self.width
        y = self.height/2
    elseif  position.align == 'left' then
        x = x
        y = self.height/2
    elseif  position.align == 'up' then
        x = self.width/2
        y = y
    elseif  position.align == 'down' then
        x = self.width/2
        y = self.height
    end
    print('calculatePositionWithAlign', x, y)
    return x, y
end

function UIobject:calculateCoordinatesAndWriteToObject(position)
    position.x, position.y = 0, 0 
    for ind, func in pairs(self.calculatePositionMethods) do
        position.x, position.y = func(self, position, position.x, position.y)
    end
    print('Calculated', position.x, position.y)
end

-- Указан отдельный объект чтобы логика указанная в Draw была сквозной, а опциональная была в render
function UIobject:render()
    if Debug.drawUiDebug then
        self:debugDraw()
    end
end

-- Указан отдельный объект чтобы логика указанная в Draw была сквозной, а опциональная была в render
function UIobject:drawCells(color)
    local cell_width = (self.width - self.margin*(self.columns-1))/self.columns
    local cell_height = (self.height - self.margin*(self.rows-1))/self.rows
    love.graphics.setColor( color.r, color.g, color.b, 1 )
    for ind = 0, self.columns * self.rows - 1, 1 do
        x = (cell_width + self.margin) * (ind % self.columns) + cell_width/2
        y = (cell_height + self.margin) * (ind/self.columns - (ind / self.columns)%1) + cell_height/2
        love.graphics.rectangle( 'line', x-cell_width/2, y-cell_height/2, cell_width, cell_height )
    end
    love.graphics.setColor( 1, 1, 1, 1 )
end

function UIobject:drawBoxAroundObject(color, lineWidth, x, y)
    local x, y = x and x or self.x, y and y or self.y
    love.graphics.setColor( color.r, color.g, color.b, 1 )
    love.graphics.setLineWidth( lineWidth )
    love.graphics.rectangle( 'line', x, y, self.width, self.height )
    love.graphics.setLineWidth( 1 )
    love.graphics.setColor( 1, 1, 1, 1 )
end

function UIobject:showOriginalPoint(color)
    love.graphics.setColor( color.r, color.g, color.b, 1 )
    love.graphics.circle( 'fill', self.x, self.y, 4, 4 )
    love.graphics.setColor( 1, 1, 1, 1 )
end

function UIobject:debugDraw()
    self:showOriginalPoint({r = 1, g = 0, b = 0 })
    self:drawBoxAroundObject({r = 0, g = 1, b = 0 }, 4)
    self:drawCells({r = 0, g = 0, b = 1 })
end


function UIobject:getObject(id)
    return self.objects[id].object
end

function UIobject:update(dt)
    for _, object in pairs(self.objects) do
        object.object:update(dt)
    end
end

function UIobject:drawBackground()
    if self.background then
        local width, height = self.background:getDimensions()
        love.graphics.draw(self.background, self.x, self.y, 0, self.width/width, self.height/height )
    end
end

-- Отображение объектов, с учётом релативной и фиксированной расположенности
function UIobject:draw()
    self:drawBackground()
    self:render()

    for _, object in pairs(self.objects) do
        print(object.position.x, object.position.y)
        love.graphics.translate(object.position.x, object.position.y)
        object.object:draw()
        love.graphics.origin()
    end

end

function UIobject:mousepressed(x, y)
    for ind, object in pairs(self.objects) do
        local targetObject = object.object
        for funcName, callback in pairs(targetObject.clickInteraction) do
            if callback.condition(targetObject, x, y) then
                callback.func(targetObject, x, y)
            end
        end
    end
end

function UIobject:mousereleased(x, y)
    for ind, object in pairs(self.objects) do
        local targetObject = object.object
        for funcName, callback in pairs(targetObject.releaseInteraction) do
            if callback.condition(targetObject, x, y) then
                callback.func(targetObject, x, y)
            end
        end
    end
end

function UIobject:wheelmoved(x, y)
    for ind, object in pairs(self.objects) do
        local targetObject = object.object
        for funcName, callback in pairs(targetObject.wheelInteraction) do
            if callback.condition(targetObject, x, y) then
                callback.func(targetObject, x, y)
            end
        end
    end
end

function UIobject:keypressed(key)
    for ind, object in pairs(self.objects) do
        local targetObject = object.object
        for funcName, callback in pairs(targetObject.keyInteraction) do
            if callback.condition(targetObject, key) then
                callback.func(targetObject, key)
            end
        end
    end
end

return UIobject