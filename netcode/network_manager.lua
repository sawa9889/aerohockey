local networkInput  = love.thread.getChannel("networkControl")
local networkOutput = love.thread.getChannel("networkOutput")

local networkManagerThread = love.thread.newThread("netcode/network_thread.lua")
networkManagerThread:start()

local NetworkPackets = require "netcode.network_packets"

local NetworkManager = {
    received = {}
}

function NetworkManager:send(packet)
    networkInput:push({ command = "send", packet = packet:serialize() })
end

function NetworkManager:receive(packetType)
    local type = NetworkPackets.types[packetType]
    local packets = self.received[type]
    self.received[type] = {}
    if not packets then packets = {} end -- nil handling
    return packets
end

function NetworkManager:connect(ip, port)
end

function NetworkManager:awaitConnection(port)
end

function NetworkManager:isConnected()
end

function NetworkManager:update(dt)
    while networkOutput:peek() do
        local channelMessage = networkOutput:pop()
        if channelMessage.type == "packet" then
            self:_saveReceived(channelMessage.data)
        end
    end
end

function NetworkManager:_saveReceived(packet)
    packet = NetworkPackets.deserialize(packet)
    if not self.received[packet.type] then
        self.received[packet.type] = {}
    end
    table.insert(self.received[packet.type], packet)
end

return NetworkManager