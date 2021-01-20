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
        self:saveReplay()
    end
end

function ReplayGame:draw()
    self.game:draw()
    love.graphics.setFont(fonts.smolPixelated)
    if Debug and Debug.showFps == 1 then
        love.graphics.print(""..tostring(love.timer.getFPS( )), 2, 2)
    end
    love.graphics.print(self.frame, 2, 16)
    if Debug and Debug.visualDesyncDebug == 1 then
        self.desyncDebugGame:draw()
    end
    love.graphics.setColor(1,0,0)
    if Debug and Debug.replayDebug == 1 and self.debugReplay[self.frame] then
        love.graphics.circle("line", self.debugReplay[self.frame].ball.position.x, self.debugReplay[self.frame].ball.position.y, 15)
    end
end

function ReplayGame:saveReplay()
    local datetime = os.date("%Y.%m.%d-%H.%M.%S")
    local replay = {
        meta = {
            version = config.replay.version,
            date = datetime
        },
        inputs = self.inputs
    }
    if not love.filesystem.getInfo("replays", "directory") then
        love.filesystem.createDirectory("replays")
    end
    replayBinary = love.data.compress("data", "zlib", serpent.line(replay, {metatostring = false, comment = false}))
    local success, message = love.filesystem.write("replays/" .. datetime .. ".rep", replayBinary)
    if success then
        print("Replay saved to %appdate%/replays/" .. datetime .. ".rep")
    else
        print("Error saving replay: " .. message)
    end
end

local function isValidReplay(replay)
    return replay and replay.meta and replay.meta.version == config.replay.version and replay.inputs
end

function love.filedropped(file)
    ok, err = file:open("r")
    if not ok then
        print("Error reading dropped file")
        return
    end
	print("Reading dropped file " .. file:getFilename())
    local data = file:read("data")
    data = love.data.decompress("string", "zlib", data)
    local okDeserialize, replay = serpent.load(data)
    if not data or not okDeserialize or not replay or not isValidReplay(replay) then
        print("Error decoding replay")
        return
    end
    StateManager.switch(states.replay, require "game", replay.inputs)
end

return ReplayGame