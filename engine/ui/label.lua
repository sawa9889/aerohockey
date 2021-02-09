Class = require "lib.hump.class"
UIobject = require "engine.ui.uiparents.uiobject"

-- Просто лейбл, для удобства выписывания всякого и для единообразности объектов в UI
Label = Class {
    __includes = UIobject,
    init = function(self, parent, parameters)
        UIobject.init(self, parent, parameters)
        self.text = parameters.text
    end
}

function Label:render()
    love.graphics.printf(self.text, 0, 0, self.width, 'center')
end

return Label