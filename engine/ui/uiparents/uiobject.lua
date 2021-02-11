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
                            local targetObject = object.object
                            for funcName, callback in pairs(targetObject.clickInteraction) do
                                if callback.condition(targetObject, x, y) then
                                    callback.func(targetObject, x, y)
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
                            local targetObject = object.object
                            for funcName, callback in pairs(targetObject.releaseInteraction) do
                                if callback.condition(targetObject, x, y) then
                                    callback.func(targetObject, x, y)
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
                            local targetObject = object.object
                            for funcName, callback in pairs(targetObject.wheelInteraction) do
                                if callback.condition(targetObject, x, y) then
                                    callback.func(targetObject, x, y)
                                end
                            end
                        end
                    end
        }
        self.keyInteraction['keypressed'] =
        {
            condition = function (object, x, y) return true end,
            func =  function (obj, key)
                        for ind, object in pairs(obj.objects) do
                            local targetObject = object.object
                            for funcName, callback in pairs(targetObject.keyInteraction) do
                                if callback.condition(targetObject, key) then
                                    callback.func(targetObject, key)
                                end
                            end
                        end
                    end
        }

        self.x, self.y = 0, 0
        self.width = nvl(parameters.width, self.parent and self.parent.width or love.graphics.getWidth())
        self.height = nvl(parameters.height, self.parent and self.parent.height or love.graphics.getHeight())

        self.objects = nvl(parameters.objects, {})
        self.background = parameters.background

        self.columns = nvl(parameters.columns, 1)
        self.rows = nvl(parameters.rows, 1)
        self.margin = nvl(parameters.margin, 10)
        self.calculatePositionMethods = {
                                            one = self.calculateRelationalPosition,
                                            two = self.calculatePositionWithAlign,
                                            -- three = self.calculatePositionInTable,
                                            four = self.calculateFixedPosition,
                                        }
                                        print(self.tag, 'Created')

        if self.columns > 1 or self.rows > 1 then
            local cell_width = (self.width - self.margin*(self.columns-1))/self.columns
            local cell_height = (self.height - self.margin*(self.rows-1))/self.rows
            for ind = 0, self.columns * self.rows - 1, 1 do
                local x = (cell_width + self.margin) * (ind % self.columns)
                local y = (cell_height + self.margin) * (ind/self.columns - (ind / self.columns)%1) 
                self:registerNewObject(ind, {fixedX = x, fixedY = y}, {width = cell_width, height = cell_height}, self)
            end 
        end

    end
}

-- Регистрация объекта в окошке, для его отображения и считывания действий
function UIobject:registerNewObject(index, position, parameters, parent)
    local object = UIobject(parent, parameters)
    if (self.rows == 1 and self.columns == 1) or not(position.row and position.column) then
        self:calculateCoordinatesAndWriteToObject(position)
        object.x, object.y = position.x, position.y
        self.objects[index] = { 
                                position = position, 
                                parameters = parameters,
                                object = object,
                              }
    else
        local row, column = position.row, position.column
        position.row, position.column = nil, nil
        print( (row-1) * self.columns + (column - 1) )
        self.objects[ (row - 1) * self.columns + (column - 1) ].object:registerObject(index, position, object)
    end
end

function UIobject:registerObject(index, position, object)
    if (self.rows == 1 and self.columns == 1) or not(position.row and position.column) then
        self:calculateCoordinatesAndWriteToObject(position)
        object.x, object.y = position.x, position.y
        self.objects[index] = { 
                                position = position, 
                                parameters = nil,
                                object = object,
                              }
    else
        local row, column = position.row, position.column
        position.row, position.column = nil, nil
        print( (row-1) * self.columns + (column - 1) )
        self.objects[ (row - 1) * self.columns + (column - 1)].object:registerObject(index, position, object)
    end
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
    -- print(self.tag, 'calculateFixedPosition', x, y)
    return x, y
end

function UIobject:calculateRelationalPosition(position, x, y)
    if position.left or position.right or position.up or position.down then
        x = x + nvl(position.left,0) + (self.width - nvl(position.right, self.width))
        y = y + nvl(position.up,0) + (self.height - nvl(position.down, self.height))
    end
    -- print(self.tag,'calculateRelationalPosition', x, y)
    return x, y
end

function UIobject:calculatePositionInTable(position, x, y)
    if position.row and position.column then
        local ind = position.row*self.columns + position.column
        local cell_width = (self.width - self.margin*(self.columns-1))/self.columns
        local cell_height = (self.height - self.margin*(self.rows-1))/self.rows
        x = (cell_width + self.margin) * (ind % self.columns)
        y = (cell_height + self.margin) * (ind/self.columns - (ind / self.columns)%1)
        -- print(self.tag,'calculatePositionInTable', x, y, ind)
    end
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
    -- print(self.tag,'calculatePositionWithAlign', x, y)
    return x, y
end

function UIobject:calculateCoordinatesAndWriteToObject(position)
    position.x, position.y = 0, 0 
    for ind, func in pairs(self.calculatePositionMethods) do
        position.x, position.y = func(self, position, position.x, position.y)
    end
    -- print(self.tag,'Calculated', position.x, position.y)
end

-- Указан отдельный объект чтобы логика указанная в Draw была сквозной, а опциональная была в render
function UIobject:render()
end

-- Указан отдельный объект чтобы логика указанная в Draw была сквозной, а опциональная была в render
function UIobject:drawCells(color)
    local cell_width = (self.width - self.margin*(self.columns-1))/self.columns
    local cell_height = (self.height - self.margin*(self.rows-1))/self.rows
    love.graphics.setColor( color.r, color.g, color.b, 1 )
    for ind = 0, self.columns * self.rows - 1, 1 do
        x = (cell_width + self.margin) * (ind % self.columns)
        y = (cell_height + self.margin) * (ind/self.columns - (ind / self.columns)%1) 
        love.graphics.rectangle( 'line', x, y, cell_width, cell_height )
    end
    love.graphics.setColor( 1, 1, 1, 1 )
end

function UIobject:drawBoxAroundObject(color, lineWidth, x, y)
    local x, y = x and x or 0, y and y or 0
    love.graphics.setColor( color.r, color.g, color.b, 1 )
    love.graphics.setLineWidth( lineWidth )
    love.graphics.rectangle( 'line', x, y, self.width, self.height )
    love.graphics.setLineWidth( 1 )
    love.graphics.setColor( 1, 1, 1, 1 )
end

function UIobject:showOriginalPoint(color)
    love.graphics.setColor( color.r, color.g, color.b, 1 )
    love.graphics.circle( 'fill', 0, 0, 4, 4 )
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
        love.graphics.draw(self.background, 0, 0, 0, self.width/width, self.height/height )
    end
end

function UIobject:draw()
    self:drawBackground()
    self:render()
    for _, object in pairs(self.objects) do
        local transform = love.math.newTransform()
        transform = transform:translate(object.position.x, object.position.y)
        love.graphics.applyTransform( transform )
        object.object:draw()
        inverse = transform:inverse()
        love.graphics.applyTransform( inverse )
    end
    if Debug.drawUiDebug then
        self:debugDraw()
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