local ReplayGame = {
    isPaused = true,
    inputs = {},
    frame = 1
}

function ReplayGame:enter(prevState, game, inputs, replayStates)
    self.inputs = inputs
    self.isPaused = false
    self.game = game
    self.game:init(function() return self:getGameInputs() end)
    self.startState = self.game:getState()
    self.replay = replayStates
    vardump(self.inputs)
end

function ReplayGame:update(dt)
    if not self.isPaused then
        if Debug and Debug.replayDebug == 1 and self.replay[self.frame] then
            vardump(self.replay[self.frame], self.game:getState())
        end
        if not self.inputs[self.frame] or not self.inputs[self.frame][1] or not self.inputs[self.frame][2] then
            print("load!")
            self.frame = 1
            self.game:loadState(self.startState)
        end
        self.game:advanceFrame()
        self.frame = self.frame + 1
    end
end

function ReplayGame:getGameInputs()
    vardump(self.frame, self.inputs[self.frame])
    return self.inputs[self.frame]
end

function ReplayGame:keypressed(key, scancode, isrepeat)
end

function ReplayGame:draw()
    self.game:draw()
    if Debug and Debug.showFps == 1 then
        love.graphics.print(""..tostring(love.timer.getFPS( )), 2, 2)
    end
    love.graphics.print(self.frame, 2, 16)
end

return ReplayGame