local Vector = require "lib.hump.vector"
local Class = require "lib.hump.class"

if not AssetManager then
    error("AssetManager is required for SoundManager")
end

local SoundEmitter

local SoundManager = {
    soundConfig = nil,
    globalVolume = 1,
    listenerPostion = Vector(0, 0),
    listenerVelocity = Vector(0, 0),
    emitters = {},
    options = {
        maxSources = 100,
        defaultEmitterOptions = {
            maxSources = 3,
            volume = 1,
            volumeVariation = 0,
            pitchVariation = 0,
        }
    },
}

function SoundManager:play(soundName, options)
    self.emitters[soundName]:play(options)
end

function SoundManager:init(soundConfig)
    self.soundConfig = soundConfig
    for soundName, soundData in pairs(soundConfig) do
        self.emitters[soundName] = self:newEmitter(soundData)
    end
    return self
end

function SoundManager:newEmitter(soundName, options)
    return SoundEmitter(soundName, options)
end

-- Usage: SoundManager:linkListener(player.position, player.velocity)
function SoundManager:linkListener(listenerPosition, listenerVelocity)
    if type(listenerPostion.x) == number and type(listenerPostion.y) == number then
        self.listenerPostion = listenerPosition
    end
    if type(listenerVelocity.x) == number and type(listenerVelocity.y) == number then
        self.listenerVelocity = listenerVelocity
    end
end

SoundEmitter = Class{
    init = function(self, soundData)
        self.soundFiles = soundData.files
        for k, soundFile in pairs(self.soundFiles) do
            if not soundFile.volume then
                soundFile.volume = 1
            end
        end

        self.options = {}
        for k, v in pairs(SoundManager.options.defaultEmitterOptions) do
            self.options[k] = v
        end
        if soundData.options then
            self:setOptions(soundData.options)
        end

        self.sources = {}
    end
}

function SoundEmitter:setOptions(options)
    for k, v in pairs(options) do
        self.options[k] = v
    end
end

function SoundEmitter:play(options)
    if #self.sources < self.options.maxSources then
        self.sources[#self.sources + 1] = {}
    end
    if not options then
        options = {
            volume = 1,
        }
    end
    for id, sourceSet in ipairs(self.sources) do
        local source = self:getPlaying(sourceSet)
        if not source then
            local soundFile = self.soundFiles[math.random(#self.soundFiles)]
            local soundFileName = soundFile.name
            if not sourceSet[soundFileName] then
                sourceSet[soundFileName] = AssetManager:getSound(soundFileName)
            end
            sourceSet[soundFileName]:setVolume(self:getVolume(soundFile, options.volume))
            sourceSet[soundFileName]:setPitch(1 + self.options.pitchVariation * (love.math.random() * 2 - 1))
            sourceSet[soundFileName]:play()
        end
    end
end

function SoundEmitter:getVolume(soundFile, customVolume)
    return math.min(1, SoundManager.globalVolume * (self.options.volume * soundFile.volume * customVolume + self.options.volumeVariation * (love.math.random() * 2 - 1)) )
end

function SoundEmitter:getPlaying(sourceSet)
    for k, source in pairs(sourceSet) do
        if source:isPlaying() then
            return source
        end
    end
    return nil
end

return function(soundData) return SoundManager:init(soundData) end
