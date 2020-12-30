Class = require "lib.hump.class"
Node = require "game.ui.uiparents.node"
Button = require "game.ui.button"

UIcontainer = Class {
    init = function(self, x, y, width, height, columns, rows, margin)
        self.x = x and x or 100
        self.y = y and y or 100
        self.width = (width and width or love.graphics.getWidth( ))
        self.height = (height and height or love.graphics.getHeight( )) - 100
        self.objects = {}
        self.columns = columns and columns or 2
        self.rows = rows and rows or 5
        self.margin = margin and margin or 10
        self.currPage = 1

        self.toolBar = {}
    end
}

function UIcontainer:refresh()
    for ind, node in pairs(self.objects) do
        if ind >= (self.currPage-1)*self.rows*self.columns and ind < self.currPage*self.rows*self.columns then
            ind = (ind % (self.rows * self.columns)) - 1
            local node_width = (self.width - self.margin*(self.rows-1))/self.rows
            local node_height = (self.height - self.margin*(self.columns-1))/self.columns
            node:refresh(self.x + (node_width+self.margin) * (ind % self.rows),
                         self.y + (node_height+self.margin) * (ind/self.rows - (ind / self.rows)%1),
                         node_width,
                         node_height)
            print(ind, node.x,node.y, node_width, node_height, ind/self.columns , (ind / self.columns)%1)
        else
            node:hide()
        end
    end
end

function UIcontainer:registerObject(node)
    table.insert(self.objects, node)
    self:refresh()
end

function UIcontainer:registerObject(name, node)
    self.objects[name, node]
    self:refresh()
end

function UIcontainer:draw()
    for _, node in pairs(self.objects) do
        node:draw()
    end
    for ind, object in pairs(self.toolBar) do
        object:draw()
    end
end

function UIcontainer:changePage(inc)
    self.currPage = self.currPage + inc > 0 and self.currPage + inc or self.currPage
    self:refresh()
end

function UIcontainer:update(dt)
    for _, node in pairs(self.objects) do
        node:update(dt)
    end
    for ind, object in pairs(self.toolBar) do
        object:update(dt)
    end
end

-- Обработчик нажатия кнопки мыши на объекты
function UIcontainer:mousepressed(x, y)
    for ind, node in pairs(self.objects) do
        if node:getCollision(x, y) then
            if node.clickInteraction then 
                node.clickInteraction(node)
            end
            if node.startHoldInteraction then 
                node.startHoldInteraction(node)
            end
        end
    end
    for ind, object in pairs(self.toolBar) do
        if object:getCollision(x, y) then
            if object.clickInteraction then 
                object.clickInteraction(self)
            end
        end
    end
end

-- Обработчик отпускания кнопки мыши
function UIcontainer:mousereleased(x, y)
    for _, node in pairs(self.objects) do
        if node.state == "dragged" then
            if node.endtHoldInteraction then 
                node.endtHoldInteraction(node)
            end
        end 
    end
end

return UIcontainer