config = {
    network = {
        packetMagic = "AERO",
        protocolVersion = "2",
        maxRollback = 10,
        delay = 3,
        syncSmoothing = 1,
        maxRemotePlayers = 1,
        connectInGame = false,
    }
}

function love.conf(t)
    t.window.title = "Aerohockey"
    t.window.width = 1366
    t.window.height = 768
end