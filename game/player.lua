local Class = require "lib.hump.class"

Player = Class {
    init = function(self, x, y, color, hc)
        self.x = x
        self.y = y
        self.size = 30
        self.color = color
        self.collider = hc:circle(x,y,self.size)
    end
}

function Player:update(dt)

end

function Player:draw()
    love.graphics.setColor(self.color)
    love.graphics.circle("fill", self.x, self.y, self.size)
end

function Player:center()
    return self.collider:center()
end

function Player:moveTo(x, y)
    self.x = x
    self.y = y
    self.collider:moveTo(x, y)
end

return Player
