Class         = require "lib.hump.class"
ReplayManager = require "replay_manager"

-- Кнопка, умеет нажиматься и писать при этом в лог, все кнопки по хорошему должны наследоваться от этого класса и накидывать кастомные действия и картинки
FilesList = Class {
    __includes = UiObject,
    init = function(self, parent, parameters)
        UiObject.init(self, parent, parameters)
        local directory = parameters.directory

        self.cell_width = (self.width - self.margin*(self.columns-1))/self.columns
        self.cell_height = (self.height - self.margin*(self.rows-1))/self.rows
        self.canvasX, self.canvasY = self.x, self.y

        local lfs = love.filesystem
        local files = lfs.getDirectoryItems(directory)
        local iter = 1
        for name, file in ipairs(files) do
            print(name)
            if file and file ~= ''  then
                local pathToFile = directory..'/'..file
                if love.filesystem.getInfo(pathToFile).type == 'file' then

                    self:registerObject('File '..pathToFile, 
                                         {row = iter, column = 1}, 
                                         Button(self, {  
                                            tag = 'File '..pathToFile, 
                                            width = self.cell_width, 
                                            height = self.cell_height, 
                                            background = AssetManager:getImage('experimental_button'),
                                            callback = function(obj, x, y) 
                                                            local replay = ReplayManager:loadReplay(pathToFile)
                                                            if replay then
                                                                StateManager.switch(states.replay, require "game", replay)
                                                            end 
                                                        end
                                        }))
                    iter = iter + 1
                end
            end
        end

        self.wheelInteraction['scrollList'] =
        {
            condition = function (object, x, y) return true end,
            func =  function (obj, x, y)
                        obj.parent.objects['files_list'].position.y = math.clamp(- #obj.objects * obj.cell_height, obj.parent.objects['files_list'].position.y + y*5, obj.canvasY )
                        self.y = math.clamp(- #obj.objects * obj.cell_height, self.y + y*5, obj.canvasY )
                    end
        }
    end
}
-- Указан отдельный объект чтобы логика указанная в Draw была сквозной, а опциональная была в render
function FilesList:render()

    -- local canvas = love.graphics.newCanvas(self.width, self.height)

    -- love.graphics.setCanvas(canvas)
    -- for _, node in pairs(self.objects) do
    --     node:draw()
    -- end
    -- love.graphics.setCanvas()

    -- -- To Do Scroll bar 
    -- local koef, koef2 = #self.objects / self.rows, self.rows / #self.objects > 1 and 1 or self.rows / #self.objects
    -- love.graphics.setColor( 0, 0, 0, 1 )
    -- love.graphics.rectangle( 'line', self.canvasX - love.graphics.getWidth()*0.05, self.canvasY , love.graphics.getWidth()*0.04, self.height )
    -- love.graphics.setColor( 1, 1, 1, 1 )
    -- love.graphics.rectangle( 'fill', self.canvasX - love.graphics.getWidth()*0.045
    --     , self.canvasY + self.height * (1 - koef2) * - ((self.y - self.canvasY)/(self.canvasY + #self.objects * self.node_height)) 
    --     , love.graphics.getWidth()*0.03, koef2 * self.height )
    -- self:drawBoxAroundObject({r = 0, g = 0, b = 0}, love.graphics.getWidth()/150, self.canvasX, self.canvasY)
    
    -- love.graphics.draw(canvas, self.canvasX, self.canvasY)
end

return FilesList