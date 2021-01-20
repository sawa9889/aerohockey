Class       = require "lib.hump.class"
UiContainer = require "engine.ui.uiparents.ui_container"
Button      = require "engine.ui.button"
Node        = require "engine.ui.uiparents.node"

-- Кнопка, умеет нажиматься и писать при этом в лог, все кнопки по хорошему должны наследоваться от этого класса и накидывать кастомные действия и картинки
FilesList = Class {
    __includes = UiContainer,
    init = function(self, x, y, width, height, margin, directory)
        UiContainer.init(self, x, y, width, height, 1, 10, margin)

        local lfs = love.filesystem
        local files = lfs.getDirectoryItems(directory)
        for _, file in ipairs(files) do
            if file and file ~= ''  then -- packed .exe finds "" for some reason
                local path_to_file = directory..'/'..file
                if love.filesystem.getInfo(path_to_file).type == 'file' then
                    self:registerObject(Node(function() print(path_to_file) end, 'File'..path_to_file))
                end
            end
        end
        self.position = 'fixed'
    end
}

return FilesList