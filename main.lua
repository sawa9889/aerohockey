local HC = require "lib.hardoncollider"

function love.load()
	hc = HC.new()
	players = {}
	players[1] = hc:circle(100,100,20)
	players[2] = hc:circle(100,200,20)
end

function love.draw()
    love.graphics.setColor(0, 0, 1)
    local shapes = hc:hash():shapes()
    for _, shape in pairs(shapes) do
        shape:draw()
    end
    love.graphics.setColor(1, 1, 1)
end

function love.update(dt)
	local x,y = love.mouse.getPosition()
	local cx,cy = players[1]:center()
	local left_border,right_border,upper_border,lower_border = 100, 800, 100, 800
	if (x > right_border or x < left_border) or (y > lower_border or y < upper_border)then
		x = cx
		y = cy

	end

	players[1]:moveTo(x, y)

    for shape, delta in pairs(HC.collisions(players[1])) do
        if shape.type ~= 'ball' then

        end
    end

end

function love.keypressed(key)
end
