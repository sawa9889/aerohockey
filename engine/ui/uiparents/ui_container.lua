Class = require "lib.hump.class"
Node = require "engine.ui.uiparents.node"
UiObject = require "engine.ui.uiparents.uiobject"

UIcontainer = Class {
    __includes = UiObject,
    init = function(self, x, y, width, height, columns, rows, margin)
        UiObject.init(self, x, y, width, height)
        self.x = x and x or 100
        self.y = y and y or 100
        self.width = (width and width or love.graphics.getWidth( ))
        self.height = (height and height or love.graphics.getHeight( )) - 100
        self.objects = {}
        self.columns = columns and columns or 2 
        self.rows = rows and rows or 5 
        self.margin = margin and margin or 10
        self.currPage = 1
    end
}

function UIcontainer:refresh()
    for ind, node in pairs(self.objects) do
        if ind > (self.currPage-1)*self.rows*self.columns and ind < self.currPage*self.rows*self.columns + 1 then
            ind = (ind % (self.rows * self.columns))
            local node_width = (self.width - self.margin*(self.columns-1))/self.columns
            local node_height = (self.height - self.margin*(self.rows-1))/self.rows
            node:refresh(self.x + (node_width + self.margin) * (ind % self.columns),
                         self.y + (node_height + self.margin) * (ind/self.columns - (ind / self.columns)%1),
                         node_width,
                         node_height)
        else
            node:hide()
        end
    end
end

function UIcontainer:registerObject(node)
    table.insert(self.objects, node)
    self:refresh()
end

function UIcontainer:draw()
    self:render()
end

function UIcontainer:changePage(inc)
    self.currPage = self.currPage + inc > 0 and self.currPage + inc or self.currPage
    self:refresh()
end

function UIcontainer:update(dt)
    for _, node in pairs(self.objects) do
        node:update(dt)
    end
end

-- Обработчик нажатия кнопки мыши на объекты
function UIcontainer:mousepressed(x, y)
    local x, y = x-self.x, y-self.y
    for ind, node in pairs(self.objects) do
        if node:getCollision(x, y) then
        print(x,y)
            if node.startClickInteraction then 
                node.startClickInteraction(node, x, y)
            end
            if node.mousepressed then 
                node.mousepressed(node, x, y)
            end
        elseif node.misClickInteraction then
            node.misClickInteraction(node, x, y)
        end
    end
end

-- Обработчик отпускания кнопки мыши
function UIcontainer:mousereleased(x, y)

end

return UIcontainer