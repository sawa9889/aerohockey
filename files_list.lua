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
end

return FilesList