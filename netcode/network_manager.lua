local networkInput  = love.thread.getChannel("networkControl")
local networkOutput = love.thread.getChannel("networkOutput")

local networkManagerThread = love.thread.newThread("netcode/network_thread.lua")
networkManagerThread:start()

local NetworkPackets = require "netcode.network_packets"

local netConfig = config.network

local log = require 'engine.logger' ("netcodeLog")

local NetworkManager = {}

function NetworkManager:init()
    self.received = {}
    self.gameStarted = false
    self.role = nil -- server, client
    self.remotePlayers = {} -- { [1] = {ip = 10.10.0.1, port = 12345, state = "connected"}, [2] = { ... }}
    self.maxRemotePlayers = netConfig.maxRemotePlayers
    self.connectInGame = netConfig.connectInGame
    self.onPlayerConnectedSubscribers = {}
end

NetworkManager:init()

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
    self:close()
    log(4, "Connecting to " .. ip .. ":" .. port)
    self.remotePlayers["server"] = { ip = ip, port = port, state = "connecting" }
    self.role = "client"
    networkInput:push({
        command = "connect",
        host = ip,
        port = port
    })
end

function NetworkManager:startServer(port, maxRemotePlayers)
    self:close()
    log(4, "Start to listen on " .. port)
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

function NetworkManager:disconnect(playerId)
    local playersToDisconnect = {}
    if not playerId then
        for id, player in pairs(self:getPlayers("connected")) do
            self:disconnect(id)
        end
    else
        local player = self:getPlayer(playerId)
        if player then
            self:sendTo(playerId, NetworkPackets.Disconnect())
            player.state = "disconnected"
        end
    end
end

function NetworkManager:close()
    self:disconnect()
    networkInput:push({
        command = "close"
    })
    log(3, "Restarting Network Manager")
    self:init()
end

function NetworkManager:getPlayers(state)
    if not state then
        return self.remotePlayers
    end
    return filter(self.remotePlayers, function(it) return it.state == state end)
end

function NetworkManager:getPlayer(id)
    return self.remotePlayers[id]
end

function NetworkManager:getOrAddPlayer(ip, port)
    for id, player in pairs(self.remotePlayers) do
        if ip == player.ip and port == player.port then
            return id
        end
    end
    table.insert(self.remotePlayers, {ip = ip, port = port})
    log(4, "Added new player " .. #self.remotePlayers .. ": " .. ip .. ":" .. port)
    return #self.remotePlayers
end

function NetworkManager:getRole()
    return self.role
end

function NetworkManager:connectedPlayersNum()
    return count(self.remotePlayers, function(it) return it.state == "connected" end)
end

function NetworkManager:handleDisconnectPackets()
    local disconnectPackets = self:receive("Disconnect")
    for _, packet in pairs(disconnectPackets) do
        local player = self:getPlayer(packet.player)
        if player then
            player.state = "disconnected"
            log(3, "Player " .. packet.player .. " has disconneted")
        end
    end
end

function NetworkManager:update(dt)
    if self.role == "client" then
        local server = self.remotePlayers["server"]
        if server.state == "connecting" then
            log(4, "Sent hello to server")
            self:sendTo("server", NetworkPackets.Hello())
            server.state = "hello_sent"
        elseif server.state == "hello_sent" then
            local acks = self:receive("HelloAck")
            for _, ack in ipairs(acks) do
                -- @todo check ip port?
                server.state = "connected"
                log(3, "Connected to server!")
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
            log(3, "Client connected")
        end
    end
    while networkOutput:peek() do
        local channelMessage = networkOutput:pop()
        if channelMessage.type == "packet" then
            self:_saveReceived(channelMessage.data)
        end
    end
    self:handleDisconnectPackets()
end

function NetworkManager:_saveReceived(data)
    local playerId = self:getOrAddPlayer(data.ip, data.port)
    if not playerId then return end
    
    local success, packetOrErr = pcall(function() return NetworkPackets.deserialize(data.packet) end)

    if not success or not packetOrErr then
        log(4, "Ignoring malformed packet!")
        log(5, packetOrErr, data)
        return
    end
    local packet = packetOrErr

    if not self.received[packet.type] then
        self.received[packet.type] = {}
    end
    table.insert(self.received[packet.type], { packet = packet, player = playerId })
end

return NetworkManager