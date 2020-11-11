local HC = require "lib.hardoncollider"
local Vector = require "lib.hump.vector"
require "utils"
require "engine.debug"

function love.load()
    hc = HC.new()

    ball_range = 15
    circle_range = 40
    arena_start = {x = 100 - circle_range, y = 100 - circle_range}
    arena_width = 600 + circle_range*2
    arena_height = 300 + circle_range*2

    players = {}
    player1_start = {x = arena_start.x + arena_width/4   , y = arena_start.y + arena_height/2 }
    player2_start = {x = arena_start.x + arena_width*3/4 , y = arena_start.y + arena_height/2 }
    players[1] = hc:circle(player1_start.x, player1_start.y, circle_range)
    players[2] = hc:circle(player2_start.x, player2_start.y, circle_range)

    ball_start = {x = arena_start.x + arena_width/2 , y = arena_start.y + arena_height/2}
    ball = {shape = hc:circle(ball_start.x, ball_start.y, ball_range), vector = Vector(0, 0) }
    ball.shape.type = 'ball'
    ball_max_speed = 10
    ball_friction = 0.991

    local border_width = 250
    local gate_hole = 40
    local right_border_start = arena_start.x + arena_width -- right_border*2 - left_border  + circle_range
    local left_border_start = arena_start.x - border_width

    local upper_border_start = arena_start.y - border_width -- upper_border - circle_range - border_width
    local lower_border_end = arena_start.y + border_width + arena_height

    local gate_height = circle_range*2 + ball_range*2
    local gate_start = arena_start.y + arena_height/2 - gate_height/2

    local horizontal_walls_width = arena_width + border_width*2

    arena = {left_upper_wall  = hc:rectangle(left_border_start, 
                                             upper_border_start, 
                                             border_width,
                                             gate_start - upper_border_start),
             left_lower_wall  = hc:rectangle(left_border_start, 
                                             gate_start + gate_height, 
                                             border_width,
                                             lower_border_end - gate_start + gate_height),
             left_gate        = hc:rectangle(left_border_start, 
                                             gate_start - border_width, 
                                             border_width - gate_hole,
                                             gate_height + border_width*2),

             right_upper_wall  = hc:rectangle(right_border_start, 
                                              upper_border_start, 
                                              border_width,
                                              gate_start - upper_border_start),
             right_lower_wall  = hc:rectangle(right_border_start, 
                                              gate_start + gate_height, 
                                              border_width,
                                              lower_border_end - gate_start + gate_height),
             right_gate        = hc:rectangle(right_border_start + gate_hole, 
                                              gate_start - border_width, 
                                              border_width - gate_hole,
                                              gate_height+ border_width*2),

             upper_wall = hc:rectangle(left_border_start, 
                                       upper_border_start, 
                                       horizontal_walls_width,
                                       border_width),
             lower_wall = hc:rectangle(left_border_start, 
                                       lower_border_end - border_width, 
                                       horizontal_walls_width,
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
                            arena_start.x,
                            arena_start.y,
                            arena_width/2,
                            arena_height)
    love.graphics.rectangle('line',
                            arena_start.x+arena_width/2,
                            arena_start.y,
                            arena_width/2,
                            arena_height)
end

function love.update(dt)
    local iterations = 10
    local player_target_x, player_target_y = love.mouse.getPosition()
    local player_x, player_y = players[1]:center()
    player_target_x = math.clamp(arena_start.x + arena_width/2, player_target_x, arena_start.x)
    player_target_y = math.clamp(arena_start.y + arena_height, player_target_y, arena_start.y)
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
    ball.vector = ball.vector * ball_friction

    for shape, delta in pairs(hc:collisions(arena.left_gate)) do
        if shape.type == 'ball' then
            print('Left gate')
        end
    end
    for shape, delta in pairs(hc:collisions(arena.right_gate)) do
        if shape.type == 'ball' then
            print('Right gate')
        end
    end
end

function love.keypressed(key)
end
