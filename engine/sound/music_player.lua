if not AssetManager then
    error("AssetManager is required for MusicPlayer")
end

local Timer = require("lib.hump.timer")

local MusicPlayer = {
    currentTrack = {
        name = nil,
        source = nil,
        metadata = nil
    },
    rhythmModule = require("engine.sound.rhythm_module"),
    globalMusicVolume = 1,
    fadingVolume = {1},
    fadingTime = 1, -- seconds
    isCurrentlyFading = false,
    fadingTypes = {
        --  _________ _________
        --  old_track|new_track
        "instant",

        --  _________   _________
        --  old_track\./new_track
        "out-in",

        --  _________  _________
        --  old_track\|new_track
        "out-instant"             
    }
}

function MusicPlayer:loadData(musicData)
    self.musicData = musicData
    if MusicPlayer.rhythmModule then
        MusicPlayer.rhythmModule:initMusicData(self.currentTrack)
    end
    return self
end

function MusicPlayer:play(track, fading)
    if self.currentTrack.name == track or self.isCurrentlyFading then
        return
    end
    if fading == "out-in" then
        self.isCurrentlyFading = true
        Timer.tween(self.fadingTime, self.fadingVolume, {0}, "linear", 
            function()
                self:_switchToTrackIfNotAlreadyPlaying(track)
                Timer.tween(self.fadingTime, self.fadingVolume, {1}, "linear",
                    function() self.isCurrentlyFading = false end
                )
            end
        )
        return
    end
    if fading == "out-instant" then
        self.isCurrentlyFading = true
        Timer.tween(self.fadingTime, self.fadingVolume, {0}, "linear", 
            function()
                self:_switchToTrackIfNotAlreadyPlaying(track)
                self.fadingVolume = {1}
                self:_setVolume()
                self.isCurrentlyFading = false
            end
        )
        return
    end
    -- for "instant" and default
    self:_switchToTrackIfNotAlreadyPlaying(track)
end

function MusicPlayer:stop()
    if self.currentTrack.source then
        self.currentTrack.source:stop()
    end
end

function MusicPlayer:setGlobalVolume(volume)
    self.globalMusicVolume = math.clamp(0, volume, 1)
    self:_setVolume()
end

function MusicPlayer:registerRhythmCallback(beatsType, fn)
    if self.rhythmModule then
        self.rhythmModule:registerRhythmCallback(beatsType, fn)
    end
end

function MusicPlayer:update(dt)
    Timer.update(dt)
    if self.isCurrentlyFading then
        self:_setVolume()
    end
    -- TODO: check music looped to go to the looping point
    if self.rhythmModule then
        self.rhythmModule:update(dt)
    end
end

function MusicPlayer:_setVolume()
    if self.currentTrack.source then
        local volume = self.globalMusicVolume
        if self.currentTrack.metadata.volume then
            volume = volume * self.currentTrack.metadata.volume
        end
        volume = volume * self.fadingVolume[1]
        self.currentTrack.source:setVolume(volume)
    end
end

function MusicPlayer:_switchToTrackIfNotAlreadyPlaying(track)
    if self.currentTrack.name == track and self.currentTrack.source then
        if not self.currentTrack.source:isPlaying() then
            self:_playCurrentSource()
        end
        return -- trying to switch to track that is already playing - do nothing
    end
    if self.currentTrack.source then
        self.currentTrack.source:stop()
    end
    local trackData = self.musicData[track]
    self.currentTrack.name = track
    self.currentTrack.metadata = trackData
    self.currentTrack.source = AssetManager:getSound(trackData.fileName)
    self:_playCurrentSource()
end

function MusicPlayer:_playCurrentSource()
    if self.currentTrack.metadata.loop == nil or self.currentTrack.metadata.loop == true then
        self.currentTrack.source:setLooping(true)
    end
    self:_setVolume()
    self.currentTrack.source:play()
end

return function(musicData) return MusicPlayer:loadData(musicData) end
