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
        connectionRetryTimer = 1, -- seconds
        disconnectTimer = 10, -- seconds
        spectator = {
            ffSpeed = 25,
            smoothing = 20,
            maxDelay = 60,
            minDelay = 25,
            framesPerAck = 10,
        }
    },
    controls = {
        replayFF = "w",
        replayAdvanceFrame = "d",
        replayPause = "space",
        replaySave = "s",
    },
    replay = {
        version = "2",
        readDroppedFiles = true,
    }
}

function love.conf(t)
    t.window.title = "Aerohockey"
    t.window.width = 1366
    t.window.height = 768
    t.identity = "aerohockey"
end