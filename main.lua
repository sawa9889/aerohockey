local HC = require "lib.hardoncollider"
local Vector = require "lib.hump.vector"
require "utils"

function love.load()
	hc = HC.new()
	players = {}
	left_border,right_border,upper_border,lower_border = 50, 400, 50, 500
	circle_range = 40
	player1_start = {x = right_border/2 , y = lower_border/2}
	player2_start = {x = right_border*3/2 , y = lower_border/2}
	players[1] = hc:circle(player1_start.x, player1_start.y, circle_range)
	players[2] = hc:circle(player2_start.x, player2_start.y, circle_range)

	ball_range = 15
	ball_start = {x = right_border, y = lower_border/2}
	ball = {shape = hc:circle(ball_start.x, ball_start.y, ball_range), vector = Vector(0, 0) }
	ball.shape.type = 'ball'
	ball_shadow = hc:circle(ball_start.x, ball_start.y, ball_range)
	ball_shadow.type = 'shadow'

	local border_width = 50
	arena = {left_wall  = hc:rectangle(left_border - circle_range - border_width, 
									   upper_border - circle_range, 
									   border_width,
									   (lower_border - upper_border + circle_range*2)),
			 right_wall = hc:rectangle(right_border + right_border - left_border  + circle_range, 
									   upper_border - circle_range, 
									   border_width,
									   (lower_border - upper_border + circle_range*2)),
			 upper_wall = hc:rectangle(left_border - circle_range, 
									   upper_border - circle_range - border_width, 
									   (right_border - left_border  + circle_range)*2,
									   border_width),
			 lower_wall = hc:rectangle(left_border - circle_range, 
									   lower_border + circle_range, 
									   (right_border - left_border  + circle_range)*2,
									   border_width)}
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
    						lower_border - upper_border + circle_range*2)
    love.graphics.rectangle('line',
    						right_border,
    						upper_border - circle_range ,
    						right_border - left_border  + circle_range,
    						lower_border - upper_border + circle_range*2)
end

function love.update(dt)
	local x,y = love.mouse.getPosition()
	local cx,cy = players[1]:center()
	x = math.clamp(right_border, x, left_border)
	y = math.clamp(lower_border, y, upper_border)

	players[1]:moveTo(x, y)
	ball.vector = ball.vector*1
	local isCollided = false
	local index = 1
	local max_index = 10
	local cx, cy = ball.shape:center()
	local pcx, pcy = players[1]:center()
	local dx = pcx - x
	local dy = pcy - y
	while not isCollided and index <= max_index do
		ball_shadow:moveTo(cx + ball.vector.x * index  / max_index, cy + ball.vector.y * index  / max_index)
		players[1]:moveTo(pcx + dx * index / max_index , pcy + dy * index / max_index)
	    for shape, delta in pairs(hc:collisions(ball_shadow)) do
	    	if shape.type ~= 'ball' then
		        ball.vector = ball.vector + delta
		        isCollided = true
		    end
	    end
	    index = index + 1
	end
    ball.shape:move(ball.vector.x, ball.vector.y)
end

function love.keypressed(key)
end
