local maxRollback = config.network.maxRollback
local RingBuffer = require "netcode.ring_buffer"

local NetworkGame = {
    states = RingBuffer(maxRollback),
    inputs = {},
    confirmedFrame = 0,
    localFrame = 0,
}

function NetworkGame:enter(prevState, game)
    self.frame = 0
    self.game = game
    self.game:init(function() return self:getGameInputs() end)
    self.states:push(self.game:getState())
    self.replay = false
end

function NetworkGame:update(dt)
    -- get stuff from net
    -- if there are packets from the past - rollback game
    -- and advance n frames
    
    if self.localFrame > self.confirmedFrame then
        self.replay = false
    end
    if not self.replay then
        local localInputs = self:getLocalInputs()
        self:addInputs(self.localFrame, 1, localInputs)
        self:addInputs(self.localFrame, 2, { x = 800 - localInputs.x, y = 490 - localInputs.y})
        self.confirmedFrame = self.localFrame
    end
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
    local inputs = self.inputs[self.localFrame]
    if not inputs then
        inputs = self.inputs[self.confirmedFrame]
    end
    return inputs
end

function NetworkGame:keypressed(key, scancode, isrepeat)
    if key == "l" and not isrepeat then
        local state = self.states:pop()
        if state then
            self.localFrame = 0
            self.game:loadState(state)
            self.replay = true
        end
    end
    if key == "s" and not isrepeat then
        self.states:push(self.game:getState())
    end
end

function NetworkGame:draw()
    self.game:draw()
end

return NetworkGame