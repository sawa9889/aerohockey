config = {
    network = {
        packetMagic = "AERO",
        protocolVersion = "3",
        maxRollback = 10,
        delay = 3,
        maxInputsPerPacket = 50,
        syncSmoothing = 1,
        maxRemotePlayers = 8,
        connectInGame = false,
        spectatorFFSpeed = 25,
        spectatorSmoothSpeed = true
    },
    controls = {
        replayFF = "w",
        replayAdvanceFrame = "d",
        replayPause = "space",
        replaySave = "s"
    },
    replay = {
        version = "1"
    }
}

function love.conf(t)
    t.window.title = "Aerohockey"
    t.window.width = 1366
    t.window.height = 768
    t.identity = "aerohockey"
end