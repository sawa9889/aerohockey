local HC = require "lib.hardoncollider"
local Vector = require "lib.hump.vector"

local Game = {}

function Game:load()
    self.hc = HC.new()

    self.ball_range = 15
    self.circle_range = 40
    self.arena_start = {x = 100 - self.circle_range, y = 100 - self.circle_range}
    self.arena_width = 600 + self.circle_range*2
    self.arena_height = 300 + self.circle_range*2

    self.players = {}
    self.player1_start = {x = self.arena_start.x + self.arena_width/4   , y = self.arena_start.y + self.arena_height/2 }
    self.player2_start = {x = self.arena_start.x + self.arena_width*3/4 , y = self.arena_start.y + self.arena_height/2 }
    self.players[1] = self.hc:circle(self.player1_start.x, self.player1_start.y, self.circle_range)
    self.players[2] = self.hc:circle(self.player2_start.x, self.player2_start.y, self.circle_range)

    self.ball_start = {x = self.arena_start.x + self.arena_width/2 , y = self.arena_start.y + self.arena_height/2}
    self.ball = {shape = self.hc:circle(self.ball_start.x, self.ball_start.y, self.ball_range), vector = Vector(0, 0) }
    self.ball.shape.type = 'ball'
    self.ball_max_speed = 10
    self.ball_friction = 0.991

    local border_width = 250
    local gate_hole = 40
    local right_border_start = self.arena_start.x + self.arena_width -- right_border*2 - left_border  + self.circle_range
    local left_border_start = self.arena_start.x - border_width

    local upper_border_start = self.arena_start.y - border_width -- upper_border - self.circle_range - border_width
    local lower_border_end = self.arena_start.y + border_width + self.arena_height

    local gate_height = self.circle_range*2 + self.ball_range*2
    local gate_start = self.arena_start.y + self.arena_height/2 - gate_height/2

    local horizontal_walls_width = self.arena_width + border_width*2

    self.arena = {
        left_upper_wall = self.hc:rectangle(
            left_border_start, 
            upper_border_start, 
            border_width,
            gate_start - upper_border_start),
        left_lower_wall = self.hc:rectangle(
            left_border_start, 
            gate_start + gate_height, 
            border_width,
            lower_border_end - gate_start + gate_height),
        left_gate = self.hc:rectangle(left_border_start, 
            gate_start - border_width, 
            border_width - gate_hole,
            gate_height + border_width*2),

        right_upper_wall  = self.hc:rectangle(
            right_border_start, 
            upper_border_start, 
            border_width,
            gate_start - upper_border_start),
        right_lower_wall  = self.hc:rectangle(
            right_border_start, 
            gate_start + gate_height, 
            border_width,
            lower_border_end - gate_start + gate_height),
        right_gate = self.hc:rectangle(
            right_border_start + gate_hole, 
            gate_start - border_width, 
            border_width - gate_hole,
            gate_height+ border_width*2),

        upper_wall = self.hc:rectangle(
            left_border_start, 
            upper_border_start, 
            horizontal_walls_width,
            border_width),
        lower_wall = self.hc:rectangle(
            left_border_start, 
            lower_border_end - border_width, 
            horizontal_walls_width,
            border_width)
    }
end

function Game:draw()
    love.graphics.setColor(0, 0, 1)
    local shapes = self.hc:hash():shapes()
    for _, shape in pairs(shapes) do
        shape:draw()
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle(
        'line',
        self.arena_start.x,
        self.arena_start.y,
        self.arena_width/2,
        self.arena_height
    )
    love.graphics.rectangle(
        'line',
        self.arena_start.x+self.arena_width/2,
        self.arena_start.y,
        self.arena_width/2,
        self.arena_height
    )
end

function Game:advanceFrame()
    local iterations = 10
    local player_target_x, player_target_y = love.mouse.getPosition()
    local player_x, player_y = self.players[1]:center()
    player_target_x = math.clamp(self.arena_start.x + self.arena_width/2, player_target_x, self.arena_start.x)
    player_target_y = math.clamp(self.arena_start.y + self.arena_height, player_target_y, self.arena_start.y)
    local player_dx = (player_target_x - player_x) / iterations
    local player_dy = (player_target_y - player_y) / iterations

    local i = 1
    while i < iterations do
        self.players[1]:move(player_dx, player_dy)
        local cx, cy = self.ball.shape:center()
        for shape, delta in pairs(self.hc:collisions(self.ball.shape)) do
            self.ball.vector = self.ball.vector + Vector(unpack(delta))/10
        end
        if self.ball.vector:len() > self.ball_max_speed then
            self.ball.vector = self.ball.vector:normalized() * self.ball_max_speed
        end
        self.ball.shape:move(self.ball.vector.x, self.ball.vector.y)
        i = i + 1
    end
    self.ball.vector = self.ball.vector * self.ball_friction

    for shape, delta in pairs(self.hc:collisions(self.arena.left_gate)) do
        if shape.type == 'ball' then
            print('Left gate')
        end
    end
    for shape, delta in pairs(self.hc:collisions(self.arena.right_gate)) do
        if shape.type == 'ball' then
            print('Right gate')
        end
    end
end

return Game
