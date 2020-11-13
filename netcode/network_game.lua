local maxRollback = config.network.maxRollback

local NetworkGame = {
    -- states = RingBuffer(maxRollback),
    inputs = {},
    confirmedFrame = 0,
    localFrame = 0
}

function NetworkGame:enter(prevState, game)
    self.frame = 0
    self.game = game
    self.game:init(function() return self:getGameInputs() end)
end

function NetworkGame:update(dt)
    -- get stuff from net
    -- if there are packets from the past - rollback game
    -- and advance n frames
    local localInputs = self:getLocalInputs()
    self:addInputs(self.localFrame, 1, localInputs)
    self:addInputs(self.localFrame, 2, { x = 800 - localInputs.x, y = 490 - localInputs.y})
    -- send inputs to opponent
    -- get inputs for both players
    -- if there is none for opponent - extrapolate
    self.game:advanceFrame()
    self.localFrame = self.localFrame + 1
    -- MVP2: sync and slow down if opponent is lagging
end

function NetworkGame:addInputs(frame, player, inputs)
    if not self.inputs[frame] then
        self.inputs[frame] = {}
    end
    self.inputs[frame][player] = inputs
end

function NetworkGame:getLocalInputs()
    local x, y = love.mouse.getPosition()
    return { x = x, y = y }
end

function NetworkGame:getGameInputs()
    return self.inputs[self.localFrame]
end

function NetworkGame:draw()
    self.game:draw()
end

return NetworkGame