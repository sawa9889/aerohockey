Class    = require "lib.hump.class"
FilesList = require "files_list"

LoadFileContainer = Class {
    __includes = UiObject,
    init = function(self, parent, parameters)
        UiObject.init(self, parent, parameters)

        self:registerObject("back_to_menu_button", 
                             {left = self.width * 0.1, down = self.height * 0.2}, 
                             Button(self, {  
                                tag = 'Back to menu', 
                                width = 200, 
                                height = 50, 
                                background = AssetManager:getImage('experimental_button'),
                                callback = function(obj, x, y) self.parent.activePage = "Main_Menu" end
                            }))

        self:registerObject("files_list", 
                             {left = self.width * 0.1, up = self.height * 0.1}, 
                             FilesList(self, {  
                                tag = 'Files list', 
                                width = self.width*0.8, 
                                height = self.height*0.7, 
                                rows = 10,
                                columns = 1,
                                callback = function(obj, x, y) self.parent.activePage = "Main_Menu" end,
                                directory = 'replays'--'%appdata%/LOVE/'
                            }))
    end
}

return LoadFileContainer