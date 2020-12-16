config = {
    network = {
        packetMagic = "AERO",
        protocolVersion = "1",
        maxRollback = 30,
        delay = 3,
        syncSmoothing = 1,
        maxRemotePlayers = 1,
        connectInGame = false,
    }
}

function love.conf(t)
    t.window.title = "Aerohockey"
    t.window.width = 800
    t.window.height = 600
end