local Player = require "game.player"
local HC = require "lib.hardoncollider"
local game = {}

function game:enter()
    self.hc = HC.new()
    local red  = {1, 0, 0}
    local blue = {0, 0, 1}

    self.players = { Player(100, 100, red, self.hc), Player(100, 200, blue, self.hc) }

    self.borders = { 
        left = 100,
        right = 800,
        up = 100,
        down = 800,
    }
end

function game:draw()
    love.graphics.setColor(0, 0, 1)
    local shapes = self.hc:hash():shapes()
    for _, shape in pairs(shapes) do
        shape:draw()
    end
    love.graphics.setColor(1, 1, 1)

    for _, player in ipairs(self.players) do
        player:draw()
    end
end

function game:update(dt)
	local x, y = love.mouse.getPosition()
	local cx,cy = self.players[1]:center()

	if (x > self.borders.right or x < self.borders.left) or (y > self.borders.down or y < self.borders.up)then
		x = cx
		y = cy
	end

	self.players[1]:moveTo(x, y)

    for shape, delta in pairs(HC.collisions(self.players[1].collider)) do
        if shape.type ~= 'ball' then

        end
    end
end

return game