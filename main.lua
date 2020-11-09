local HC = require "lib.hardoncollider"

function love.load()
	hc = HC.new()
	players = {}
	left_border,right_border,upper_border,lower_border = 50, 400, 50, 500
	circle_range = 20
	player1_start = {x = 400, y = 100}
	player2_start = {x = 400, y = 400}
	players[1] = hc:circle(player1_start.x, player1_start.y, circle_range)
	players[2] = hc:circle(player2_start.x, player2_start.y, circle_range)
end

function love.draw()
    love.graphics.setColor(0, 0, 1)
    local shapes = hc:hash():shapes()
    for _, shape in pairs(shapes) do
        shape:draw()
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle('line',
    						left_border  - circle_range,
    						upper_border - circle_range,
    						right_border - left_border  + circle_range,
    						lower_border - upper_border + circle_range)
    love.graphics.rectangle('line',
    						left_border  + right_border-left_border,
    						upper_border - circle_range ,
    						right_border - left_border  + circle_range,
    						lower_border - upper_border + circle_range)
end

function love.update(dt)
	local x,y = love.mouse.getPosition()
	local cx,cy = players[1]:center()
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
