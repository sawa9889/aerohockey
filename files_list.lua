Class         = require "lib.hump.class"
UiContainer   = require "engine.ui.uiparents.ui_container"
Button        = require "engine.ui.button"
Node          = require "engine.ui.uiparents.node"
ReplayManager = require "replay_manager"

-- Кнопка, умеет нажиматься и писать при этом в лог, все кнопки по хорошему должны наследоваться от этого класса и накидывать кастомные действия и картинки
FilesList = Class {
    __includes = UiContainer,
    init = function(self, x, y, width, height, margin, directory)
        UiContainer.init(self, x, y, width, height, 1, 10, margin)
        local directory = "replays"
        self.node_width = (self.width - self.margin*(self.columns-1))/self.columns
        self.node_height = (self.height - self.margin*(self.rows-1))/self.rows
        self.canvasX, self.canvasY = x, y
        local lfs = love.filesystem
        local files = lfs.getDirectoryItems(directory)
        for _, file in ipairs(files) do
            if file and file ~= ''  then -- packed .exe finds "" for some reason
                local pathToFile = directory..'/'..file
                if love.filesystem.getInfo(pathToFile).type == 'file' then
                    self:registerObject(Node(
                        function()
                            local replay = ReplayManager:loadReplay(pathToFile)
                            if replay then
                                StateManager.switch(states.replay, require "game", replay)
                            end
                        end, 'File '..pathToFile))
                end
            end
        end
        self.position = 'fixed'
    end
}
-- Указан отдельный объект чтобы логика указанная в Draw была сквозной, а опциональная была в render
function FilesList:render()

    local canvas = love.graphics.newCanvas(self.width, self.height)

    love.graphics.setCanvas(canvas)
    for _, node in pairs(self.objects) do
        node:draw()
    end
    love.graphics.setCanvas()

    -- To Do Scroll bar 
    local koef, koef2 = #self.objects / self.rows, self.rows / #self.objects > 1 and 1 or self.rows / #self.objects
    love.graphics.setColor( 0, 0, 0, 1 )
    love.graphics.rectangle( 'line', self.canvasX - love.graphics.getWidth()*0.05, self.canvasY , love.graphics.getWidth()*0.04, self.height )
    love.graphics.setColor( 1, 1, 1, 1 )
    love.graphics.rectangle( 'fill', self.canvasX - love.graphics.getWidth()*0.045
        , self.canvasY + self.height * (1 - koef2) * - ((self.y - self.canvasY)/(self.canvasY + #self.objects * self.node_height)) 
        , love.graphics.getWidth()*0.03, koef2 * self.height )

    self:drawBoxAroundObject({r = 0, g = 0, b = 0}, love.graphics.getWidth()/150, self.canvasX, self.canvasY)
    
    love.graphics.draw(canvas, self.canvasX, self.canvasY)
end

function FilesList:wheelMoved(x, y)
    self.y = math.clamp(- #self.objects * self.node_height, self.y + y*5, self.canvasY )
    print(x, y)
    self:refresh()
end

function FilesList:refresh()
    for ind, node in pairs(self.objects) do
        ind = ind - 1
        local x, y = self.x - self.canvasX, self.y - self.canvasY
        node:refresh(x + (self.node_width + self.margin) * (ind % self.columns),
                     y + (self.node_height + self.margin) * ind,
                     self.node_width,
                     self.node_height)
    end
end

return FilesList