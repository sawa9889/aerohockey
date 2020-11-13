local maxRollback = config.network.maxRollback

local NetworkGame = {
    -- states = RingBuffer(maxRollback),
    inputs = {
        player1 = {},
        player2 = {}
    },
    frame = 0
}

function NetworkGame:enter(prevState, game)
    self.frame = 0
    self.game = game
    self.game:load()
end

function NetworkGame:update(dt)
    -- get stuff from net
    -- if there are packets from the past - rollback game
    -- and advance n frames
    -- save user inputs to table
    -- send inputs to opponent
    -- get inputs for both players
    -- if there is none for opponent - extrapolate
    self.game:advanceFrame()
    -- MVP2: sync and slow down if opponent is lagging
end

function NetworkGame:draw()
    self.game:draw()
end

return NetworkGame