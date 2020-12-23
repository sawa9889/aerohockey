local HC = require "lib.hardoncollider"
local Vector = require "lib.hump.vector"

local Game = {}

local ball_queue = {
    length = 10,
    queue_arr = {},
    put = function (self, val)
        if #self.queue_arr >= self.length then
            for ind, val in pairs(self.queue_arr) do
                self.queue_arr[ind] = self.queue_arr[ind+1]
            end
            self.queue_arr[self.length+1] = val
        else 
            table.insert(self.queue_arr, val)
        end
    end,
    get = function ()
        local result = queue_arr[1]
    end
}

function Game:init(inputSource)

    self.background = AssetManager:getImage('playground')
    self.width, self.height = self.background:getDimensions()
    local windowWidth, windowHeight = love.graphics.getWidth(), love.graphics.getHeight()
    self.scaleX, self.scaleY = windowWidth/self.width, windowHeight/self.height

    self.hc = HC.new()

    self.inputSource = inputSource

    self.ball_range = 30
    self.ball_queue = ball_queue
    self.circle_range = 40
    self.arena_start = {x = 0, y = 16*self.scaleY}
    self.arena_width = self.width*self.scaleX
    self.arena_height = (self.height-16)*self.scaleY

    self.players = {}
    self.player1_start = {x = self.arena_start.x + self.arena_width/4   , y = self.arena_start.y + self.arena_height/2 }
    self.player2_start = {x = self.arena_start.x + self.arena_width*3/4 , y = self.arena_start.y + self.arena_height/2 }
    self.players[1] = self.hc:circle(self.player1_start.x, self.player1_start.y, self.circle_range)
    self.players[2] = self.hc:circle(self.player2_start.x, self.player2_start.y, self.circle_range)

    self.ball_start = {x = self.arena_start.x + self.arena_width/2 , y = self.arena_start.y + self.arena_height/2}
    self.ball = {shape = self.hc:circle(self.ball_start.x, self.ball_start.y, self.ball_range), velocity = Vector(0, 0) }
    self.ball.shape.type = 'ball'
    self.ball_max_speed = 8
    self.ball_friction = 0.991

    local border_width = 250
    local gate_hole = 40
    local right_border_start = self.arena_start.x + self.arena_width -- right_border*2 - left_border  + self.circle_range
    local left_border_start = self.arena_start.x - border_width

    local upper_border_start = self.arena_start.y - border_width -- upper_border - self.circle_range - border_width
    local lower_border_end = self.arena_start.y + border_width + self.arena_height

    local gate_height = self.circle_range*2 + self.ball_range*4
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
    self.leftPlayerPoints = 0
    self.rightPlayerPoints = 0
end

function Game:getState()
    local state = {
        players = {
            [1] = Vector(self.players[1]:center()),
            [2] = Vector(self.players[2]:center())
        },
        ball = {
            position = Vector(self.ball.shape:center()),
            velocity = self.ball.velocity:clone()
        },
        score = {
            [1] = self.leftPlayerPoints,
            [2] = self.rightPlayerPoints
        }
    }
    if Debug and Debug.showStatesLoadSave == 1 then
        print("Serialized state")
        vardump(state)
    end
    return state
end

function Game:loadState(state)
    if Debug and Debug.showStatesLoadSave == 1 then
        print("Loaded state")
        vardump(state)
    end
    self.players[1]:moveTo(state.players[1].x, state.players[1].y)
    self.players[2]:moveTo(state.players[2].x, state.players[2].y)
    self.ball.velocity = state.ball.velocity:clone()
    self.ball.shape:moveTo(state.ball.position.x, state.ball.position.y)
    self.leftPlayerPoints = state.score[1]
    self.rightPlayerPoints = state.score[2]
end

function Game:draw()
    
    love.graphics.draw(self.background, self.x, self.y, 0, self.scaleX, self.scaleY )

    love.graphics.setColor( 1, 1, 1, 1 )
    love.graphics.setFont(fonts.sevenSegment)
    love.graphics.print(self.leftPlayerPoints, 65*self.scaleX, 2*self.scaleY, 0)
    love.graphics.print(self.rightPlayerPoints, 82*self.scaleX, 2*self.scaleY, 0)
    local ballPos, player1Pos, player2Pos = Vector(self.ball.shape:center()), Vector(self.players[1]:center()), Vector(self.players[2]:center())
    local ballPos, player1Pos, player2Pos = Vector(self.ball.shape:center()), Vector(self.players[1]:center()), Vector(self.players[2]:center())
    -- Draw players
    local img = AssetManager:getImage('bat')
    local width, height = img:getDimensions()
    local circle_index = self.circle_range/(width/2)
    love.graphics.draw(img, player1Pos.x, player1Pos.y, 0, circle_index, circle_index, (width/4)*circle_index, (height/4)*circle_index  )
    img = AssetManager:getImage('bat_2')
    love.graphics.draw(img, player2Pos.x, player2Pos.y, 0, circle_index, circle_index, (width/4)*circle_index, (height/4)*circle_index  )

    -- Draw ball
    img = AssetManager:getImage('ball')
    width, height = img:getDimensions()
    ball_index = self.ball_range/(width/2)
    love.graphics.draw(img, ballPos.x, ballPos.y, 0, ball_index, ball_index, (width/4)*ball_index, (height/4)*ball_index  )

    for ind, vector in pairs(self.ball_queue.queue_arr) do
        love.graphics.draw(img, vector.x, vector.y, 0, ball_index*(ind * 0.1), ball_index*(ind * 0.1), (width/4)*ball_index, (height/4)*ball_index )
    end

    love.graphics.setColor( 1, 1, 1, 1 )

end

function Game:getPlayerdx(target, playerNum)
    local playerPos = Vector(self.players[playerNum]:center())
    if playerNum == 1 then
        target.x = math.clamp(self.arena_start.x - self.circle_range + self.arena_width/2, target.x, self.arena_start.x + self.circle_range )
    else
        target.x = math.clamp(self.arena_start.x + self.circle_range + self.arena_width/2, target.x, self.arena_start.x - self.circle_range + self.arena_width)
    end
    target.y = math.clamp(self.arena_start.y - self.circle_range + self.arena_height, target.y, self.arena_start.y + self.circle_range)
    return target - playerPos
end

function Game:roundBallVectors()
    -- fkn lua doesn't know how to round
    local function round(num, numDecimalPlaces)
        local mult = 10^(numDecimalPlaces or 0)
        return math.floor(num * mult + 0.5) / mult
    end
    local decPlaces = 5
    self.ball.velocity.x = round(self.ball.velocity.x, decPlaces)
    self.ball.velocity.y = round(self.ball.velocity.y, decPlaces)
    local ballPos = Vector(self.ball.shape:center())
    ballPos.x = round(ballPos.x, decPlaces)
    ballPos.y = round(ballPos.y, decPlaces)
    self.ball.shape:moveTo(ballPos:unpack())
end

function Game:advanceFrame()
    local iterations = 10
    local inputs = self.inputSource()
    local player_dPos = {}
    player_dPos[1] = self:getPlayerdx(Vector(inputs[1].x, inputs[1].y), 1) / iterations
    player_dPos[2] = self:getPlayerdx(Vector(inputs[2].x, inputs[2].y), 2) / iterations

    local i = 1
    while i <= iterations do
        self.players[1]:move(player_dPos[1].x, player_dPos[1].y)
        self.players[2]:move(player_dPos[2].x, player_dPos[2].y)
        for shape, delta in pairs(self.hc:collisions(self.ball.shape)) do
            self.ball.velocity = self.ball.velocity + Vector(unpack(delta))/iterations
        end
        if self.ball.velocity:len() > self.ball_max_speed then
            self.ball.velocity = self.ball.velocity:normalized() * self.ball_max_speed
        end
        self.ball.shape:move(self.ball.velocity.x, self.ball.velocity.y)
        i = i + 1
    end
    self.ball.velocity = self.ball.velocity * self.ball_friction
    self.ball_queue:put(Vector(self.ball.shape:center()))
    self:roundBallVectors() -- @hack: it keeps to desync on some rounding errors
    -- single different digit on 10^-12 gets bigger over time and causes desync
    -- hopefully, it doesn't get big enough to get through rounding

    for shape, delta in pairs(self.hc:collisions(self.arena.left_gate)) do
        if shape.type == 'ball' then
            self.rightPlayerPoints = self.rightPlayerPoints + 1
        end
    end
    for shape, delta in pairs(self.hc:collisions(self.arena.right_gate)) do
        if shape.type == 'ball' then
            self.leftPlayerPoints = self.leftPlayerPoints + 1
        end
    end
end

return Game
