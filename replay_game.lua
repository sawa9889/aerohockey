ReplayManager = require "replay_manager"

local ReplayGame = {
    isPaused = true,
    inputs = {},
    frame = 1,
    ffSpeed = 25
}

function ReplayGame:enter(prevState, game, replay, loop)
    self.inputs = replay.inputs
    self.isPaused = false
    self.frame = 1
    self.loop = loop
    self.game = game
    self.game:init(function() return self:getGameInputs() end)
    if Debug and Debug.visualDesyncDebug == 1 then
        self.desyncDebugGame = require "game"
    end
    self.startState = self.game:getState()
    self.debugReplay = replay.states
end

function ReplayGame:update(dt)
    if not self.isPaused then
        if love.keyboard.isDown(config.controls.replayFF) then
            local i = self.ffSpeed
            while i > 0 do
                self:advanceFrame()
                i = i - 1
            end
        end
        self:advanceFrame()
    end
end

function ReplayGame:advanceFrame()
    if Debug and Debug.replayDebug == 1 and self.debugReplay[self.frame] then
        -- vardump(self.frame, self.debugReplay[self.frame].ball, self.game:getState().ball)
        local desync = (self.debugReplay[self.frame].ball.position - self.game:getState().ball.position):len()
        if desync > 0 then
            print("Frame: " .. self.frame .. " Ball desync: " .. desync)
        end
    end
    if Debug and Debug.visualDesyncDebug == 1 then
        if self.debugReplay[self.frame] then
            self.desyncDebugGame:loadState(self.debugReplay[self.frame])
        end
    end
    if not self.inputs[self.frame] or not self.inputs[self.frame][1] or not self.inputs[self.frame][2] then
        if self.loop then
            print("Loop replay")
            self.frame = 1
            self.game:loadState(self.startState)
        else
            return
        end
    end
    self.game:advanceFrame()
    self.frame = self.frame + 1
end

function ReplayGame:getGameInputs()
    return self.inputs[self.frame]
end

function ReplayGame:keypressed(key, scancode, isrepeat)
    if key == config.controls.replayPause and not isrepeat then
        self.isPaused = not self.isPaused
    end
    if key == config.controls.replayAdvanceFrame and not isrepeat and self.isPaused then
        self:advanceFrame()
    end
    if key == config.controls.replaySave and not isrepeat then
        ReplayManager:saveReplay(self.inputs)
    end
end

function ReplayGame:draw()
    self.game:draw()
    love.graphics.setFont(fonts.smolPixelated)
    if Debug and Debug.showFps == 1 then
        love.graphics.print(""..tostring(love.timer.getFPS( )), 2, 2)
    end
    love.graphics.print("Frame: "..self.frame, 2, 16)
    love.graphics.print(string.format(
        "Controls:\n%s - save replay to file\n%s - to fast forward\n%s - to pause\n%s - advance frame on pause",
        config.controls.replaySave,
        config.controls.replayFF,
        config.controls.replayPause,
        config.controls.replayAdvanceFrame
    ), 2, 30)
    if Debug and Debug.visualDesyncDebug == 1 then
        self.desyncDebugGame:draw()
    end
    love.graphics.setColor(1,0,0)
    if Debug and Debug.replayDebug == 1 and self.debugReplay[self.frame] then
        love.graphics.circle("line", self.debugReplay[self.frame].ball.position.x, self.debugReplay[self.frame].ball.position.y, 15)
    end
end

return ReplayGame