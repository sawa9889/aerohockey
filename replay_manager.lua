local ReplayManager = {
    compressFormat = "zlib"
}

function ReplayManager:saveReplay(inputs)
    local datetime = os.date("%Y.%m.%d-%H.%M.%S")
    local replay = {
        meta = {
            version = config.replay.version,
            date = datetime
        },
        inputs = inputs
    }
    if not love.filesystem.getInfo("replays", "directory") then
        love.filesystem.createDirectory("replays")
    end

    local success, message = love.filesystem.write("replays/" .. datetime .. ".rep", self:packReplay(replay))
    if success then
        print("Replay saved to %appdate%/replays/" .. datetime .. ".rep")
    else
        print("Error saving replay: " .. message)
    end
end

function ReplayManager:loadReplay(filePath)
    local data, err = love.filesystem.read("data", filePath)
    if not data then
        error("Failed to read replay file: " .. err)
    end
    return self:unpackReplay(data)
end

function ReplayManager:packReplay(replay)
    return love.data.compress("data", self.compressFormat, serpent.line(replay, {metatostring = false, comment = false}))
end

function ReplayManager:isValidReplay(replay)
    return replay and replay.meta and replay.meta.version == config.replay.version and replay.inputs
end

function ReplayManager:unpackReplay(data)
    local success, data = pcall(function() return love.data.decompress("string", self.compressFormat, data) end)
    if not success or not data then
        vardump(data)
        print("Error reading replay")
        return
    end
    local okDeserialize, replay = serpent.load(data)
    if not data or not okDeserialize or not replay or not self:isValidReplay(replay) then
        vardump(data)
        print("Error decoding replay")
        return
    end
    return replay
end

if config.replay.readDroppedFiles then
    function love.filedropped(file)
        ok, err = file:open("r")
        if not ok then
            print("Error reading dropped file")
            return
        end
        print("Reading dropped file " .. file:getFilename())
        local replay = ReplayManager:unpackReplay(file:read("data"))
        if replay then
            StateManager.switch(states.replay, require "game", replay)
        end
    end
end

return ReplayManager