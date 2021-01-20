local ReplayGame = {
    isPaused = true,
    inputs = {},
    frame = 1,
    ffSpeed = config.network.spectatorFFSpeed
}

function ReplayGame:enter(prevState, game)
    self.isPaused = false
    self.frame = 1
    self.game = game
    self.game:init(function() return self:getGameInputs() end)
    self.startState = self.game:getState()
    -- send ack 0
end

function ReplayGame:update(dt)
    -- recieve inputs
    -- send ack
    -- put them into table
    -- if not recieved inputs for n seconds - send ack again
    if not self.isPaused then
        if self.frame < confirmedFrame then
            local i = math.min(self.ffSpeed, confirmedFrame - self.frame) -- and divide that to some smoothing
            while i > 0 do
                self:advanceFrame()
                i = i - 1
            end
        end
        self:advanceFrame()
    end
end

function ReplayGame:advanceFrame()
    if not self.inputs[self.frame] or not self.inputs[self.frame][1] or not self.inputs[self.frame][2] then
        return
    end
    self.game:advanceFrame()
    self.frame = self.frame + 1
end

function ReplayGame:getGameInputs()
    return self.inputs[self.frame]
end

function ReplayGame:keypressed(key, scancode, isrepeat)
end

function ReplayGame:draw()
    self.game:draw()
    love.graphics.setFont(fonts.smolPixelated)
    if Debug and Debug.showFps == 1 then
        love.graphics.print(""..tostring(love.timer.getFPS( )), 2, 2)
    end
    -- debug widget as in network game
end

return ReplayGame