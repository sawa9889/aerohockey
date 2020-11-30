local networkInput  = love.thread.getChannel("networkControl")
local networkOutput = love.thread.getChannel("networkOutput")

local networkManagerThread = love.thread.newThread("netcode/network_thread.lua")
networkManagerThread:start()

local NetworkPackets = require "netcode.network_packets"

local netConfig = config.network

local NetworkManager = {
    received = {},
    gameStarted = false,
    role = nil, -- server, client
    remotePlayers = {}, -- { [1] = {ip = 10.10.0.1, port = 12345, state = "connected"}, [2] = { ... }}
    maxRemotePlayers = netConfig.maxRemotePlayers,
    connectInGame = netConfig.connectInGame
}

function NetworkManager:sendTo(playerId, packet)
    local player = self.remotePlayers[playerId]
    networkInput:push({
        command = "send",
        packet = packet:serialize(),
        ip = player.ip,
        port = player.port
    })
end

function NetworkManager:send(packet)
    for id, player in pairs(self.remotePlayers) do
        self:sendTo(id, packet)
    end
end

function NetworkManager:receive(packetType) -- @todo player filtering?
    local type = NetworkPackets.types[packetType]
    local packets = self.received[type]
    self.received[type] = {}
    if not packets then packets = {} end -- nil handling
    return packets
end

function NetworkManager:connectTo(ip, port)
    self.remotePlayers["server"] = { ip = ip, port = port, state = "connecting" }
    self.role = "client"
    networkInput:push({
        command = "connect",
        host = ip,
        port = port
    })
end

function NetworkManager:startServer(port, maxRemotePlayers)
    self.role = "server"
    if maxRemotePlayers then
        self.maxRemotePlayers = maxRemotePlayers
    end
    networkInput:push({
        command = "awaitConnection",
        host = "0.0.0.0",
        port = port
    })
end

function NetworkManager:getPlayers(state)
    if not state then
        return self.remotePlayers
    end
    return filter(self.remotePlayers, function(it) return it.state == state end)
end

function NetworkManager:getOrAddPlayer(ip, port)
    for id, player in pairs(self.remotePlayers) do
        if ip == player.ip and port == player.port then
            return id
        end
    end
    table.insert(self.remotePlayers, {ip = ip, port = port})
    return #self.remotePlayers
end

function NetworkManager:connectedPlayersNum()
    return count(self.remotePlayers, function(it) return it.state == "connected" end)
end

function NetworkManager:update(dt)
    if self.role == "client" then
        local server = self.remotePlayers["server"]
        if server.state == "connecting" then
            print("send hello")
            self:sendTo("server", NetworkPackets.Hello())
            server.state = "hello_sent"
        elseif server.state == "hello_sent" then
            local acks = self:receive("HelloAck")
            for _, ack in ipairs(acks) do
                -- @todo check ip port?
                server.state = "connected"
                print("Client connected to server!")
            end
        end
    elseif self.role == "server" then
        local helloPackets = self:receive("Hello")
        for _, hello in ipairs(helloPackets) do
            local playerId = hello.player
            local player = self.remotePlayers[playerId]
            -- if playersNum > maxRemotePlayers then send error and disconnect
            self:sendTo(playerId, NetworkPackets.HelloAck())
            player.state = "connected"
            print("Player connected")
        end
    end
    while networkOutput:peek() do
        local channelMessage = networkOutput:pop()
        if channelMessage.type == "packet" then
            self:_saveReceived(channelMessage.data)
        end
    end
end

function NetworkManager:_saveReceived(data)
    local playerId = self:getOrAddPlayer(data.ip, data.port)
    if not playerId then return end
    
    local packet = NetworkPackets.deserialize(data.packet)

    if not self.received[packet.type] then
        self.received[packet.type] = {}
    end
    table.insert(self.received[packet.type], { packet = packet, player = playerId })
end

return NetworkManager