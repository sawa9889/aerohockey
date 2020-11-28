local ReplayGame = {
    isPaused = true,
    inputs = {},
    frame = 1
}

function ReplayGame:enter(prevState, game, inputs, replayStates)
    self.inputs = inputs
    self.isPaused = false
    self.frame = 1
    self.game = game
    self.game:init(function() return self:getGameInputs() end)
    if Debug and Debug.visualDesyncDebug == 1 then
        self.desyncDebugGame = require "game"
    end
    self.startState = self.game:getState()
    self.replay = replayStates
end

function ReplayGame:update(dt)
    if not self.isPaused then
        self:advanceFrame()
    end
end

function ReplayGame:advanceFrame()
    if Debug and Debug.replayDebug == 1 and self.replay[self.frame] then
        -- vardump(self.frame, self.replay[self.frame].ball, self.game:getState().ball)
        local desync = (self.replay[self.frame].ball.position - self.game:getState().ball.position):len()
        if desync > 0 then
            print("Frame: " .. self.frame .. " Ball desync: " .. desync)
        end
    end
    if Debug and Debug.visualDesyncDebug == 1 then
        if self.replay[self.frame] then
            self.desyncDebugGame:loadState(self.replay[self.frame])
        end
    end
    if not self.inputs[self.frame] or not self.inputs[self.frame][1] or not self.inputs[self.frame][2] then
        print("load!")
        self.frame = 1
        self.game:loadState(self.startState)
    end
    self.game:advanceFrame()
    self.frame = self.frame + 1
end

function ReplayGame:getGameInputs()
    return self.inputs[self.frame]
end

function ReplayGame:keypressed(key, scancode, isrepeat)
    if key == "space" and not isrepeat then
        self.isPaused = not self.isPaused
    end
    if key == "d" and not isrepeat and self.isPaused then
        self:advanceFrame()
    end
end

function ReplayGame:draw()
    self.game:draw()
    if Debug and Debug.showFps == 1 then
        love.graphics.print(""..tostring(love.timer.getFPS( )), 2, 2)
    end
    love.graphics.print(self.frame, 2, 16)
    if Debug and Debug.visualDesyncDebug == 1 then
        self.desyncDebugGame:draw()
    end
    love.graphics.setColor(1,0,0)
    if Debug and Debug.replayDebug == 1 and self.replay[self.frame] then
        love.graphics.circle("line", self.replay[self.frame].ball.position.x, self.replay[self.frame].ball.position.y, 15)
    end
end

return ReplayGame