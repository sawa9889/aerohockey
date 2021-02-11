Class         = require "lib.hump.class"
ReplayManager = require "replay_manager"

-- Кнопка, умеет нажиматься и писать при этом в лог, все кнопки по хорошему должны наследоваться от этого класса и накидывать кастомные действия и картинки
FilesList = Class {
    __includes = UiObject,
    init = function(self, parent, parameters)
        UiObject.init(self, parent, parameters)
        local directory = parameters.directory

        self.cellWidth = (self.width - self.margin*(self.columns-1))/self.columns
        self.cellHeight = (self.height - self.margin*(self.rows-1))/self.rows
        self.firctCellY = 0
        print('Start counting ')
        for ind, obj in pairs(self.objects) do
            print(ind, obj)
        end
        local lfs = love.filesystem
        local files = lfs.getDirectoryItems(directory)
        local iter = 1
        for name, file in ipairs(files) do
            if file and file ~= ''  then
                local pathToFile = directory..'/'..file
                if love.filesystem.getInfo(pathToFile).type == 'file' then

                    self:registerObject('File '..pathToFile, 
                                         {row = iter, column = 1}, 
                                         Button(self, {  
                                            tag = 'File '..pathToFile, 
                                            width = self.cellWidth, 
                                            height = self.cellHeight, 
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
            			obj:moveObjects(y)
                    end
        }
    end
}

function FilesList:moveObjects(y)
    local cnt = count(self.objects, function() return true end)
    local changeY = (self.firctCellY + y*5 <= 0 and (self.firctCellY + y*5 >= - (cnt-1) * (self.cellHeight+self.margin) and y*5 or 0) or 0 )
    self.firctCellY = self.firctCellY + changeY
    for _, object in pairs(self.objects) do
        object.position.y = object.position.y + changeY
    end
end

-- Указан отдельный объект чтобы логика указанная в Draw была сквозной, а опциональная была в render
function FilesList:draw()
	defaultCanvas = love.graphics.getCanvas()
	canvas = love.graphics.newCanvas(self.width, self.height)
    love.graphics.setCanvas(canvas)

    local transform = love.math.newTransform()
    transform = transform:translate(-self.x, -self.y)
    love.graphics.applyTransform( transform )

	UIobject.draw(self)

    inverse = transform:inverse()
    love.graphics.applyTransform( inverse )

    love.graphics.setCanvas(defaultCanvas)
    love.graphics.draw(canvas, 0, 0)
end

return FilesList