local HC = require "lib.hardoncollider"
local Vector = require "lib.hump.vector"
require "utils"
require "engine.debug"

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
	ball_max_speed = 10

	local border_width = 250
	arena = {left_wall  = hc:rectangle(left_border - circle_range - border_width, 
									   upper_border - circle_range, 
									   border_width,
									   (lower_border - upper_border + circle_range*2)),
			 right_wall = hc:rectangle(right_border + right_border - left_border  + circle_range, 
									   upper_border - circle_range, 
									   border_width,
									   (lower_border - upper_border + circle_range*2)),
			 upper_wall = hc:rectangle(left_border - circle_range - border_width, 
									   upper_border - circle_range - border_width, 
									   (right_border - left_border  + circle_range+ border_width)*2,
									   border_width),
			 lower_wall = hc:rectangle(left_border - circle_range - border_width, 
									   lower_border + circle_range, 
									   (right_border - left_border  + circle_range + border_width)*2,
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
	local iterations = 10
	local player_target_x, player_target_y = love.mouse.getPosition()
	local player_x, player_y = players[1]:center()
	player_target_x = math.clamp(right_border, player_target_x, left_border)
	player_target_y = math.clamp(lower_border, player_target_y, upper_border)
	local player_dx = (player_target_x - player_x) / iterations
	local player_dy = (player_target_y - player_y) / iterations

	local i = 1
	while i < iterations do
		players[1]:move(player_dx, player_dy)
		ball.vector = ball.vector
		local cx, cy = ball.shape:center()
		for shape, delta in pairs(hc:collisions(ball.shape)) do
			ball.vector = ball.vector + Vector(unpack(delta))/10
		end
		if ball.vector:len() > ball_max_speed then
			ball.vector = ball.vector:normalized() * ball_max_speed
		end
		ball.shape:move(ball.vector.x, ball.vector.y)
		i = i + 1
	end
end

function love.keypressed(key)
end
