Class = require "lib.hump.class"
UIobject = require "game.ui.uiparents.uiobject"

-- Просто лейбл, для удобства выписывания всякого и для единообразности объектов в UI
Label = Class {
    __includes = UIobject,
    init = function(self, parent, parameters)
        UIobject.init(self, parent, parameters)
    end
}

function Label:render()
    love.graphics.print(self.tag, self.x, self.y)
end

return Label