local serpent = require "lib.debug.serpent" 

settings = {
    values = { -- default values are overwritten by file
        ip = "127.0.0.1",
        port = "12345"
    }
}

function settings:get(key)
    if not self.values[key] then
        print("Unknown setting " .. key)
        return
    end
    return self.values[key]
end

function settings:set(key, value)
    self.values[key] = value
end

function settings:load()
    if love.filesystem.getInfo("settings.lua") then
        local settingsString, err = love.filesystem.read("settings.lua")
        if not settingsString then
            error("Failed to read settings file: " .. err)
        end
        local ok, settingsFile = serpent.load(settingsString)
        if ok then
            for k, v in pairs(self.values) do
                if settingsFile[k] then
                    self.values[k] = settingsFile[k]
                end
            end
        else
            self:save()
        end
    else
        self:save()
    end
end

function settings:save()
    local settingsString = serpent.block(self.values, {comment = false})
	love.filesystem.write("settings.lua", settingsString)
end

return settings
