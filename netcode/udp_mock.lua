local Timer = require "lib.hump.timer"
require 'love.math'
require 'engine.debug'

local SocketMock = {

}
-- он так работать не будет, нужно смотреть в пакеты и отвечать соответственно
local UdpMock = {
    timer = Timer.new(),
    lag = 0.01,
    received = {}
}

function SocketMock:udp()
    return UdpMock
end

function UdpMock:settimeout(seconds)
end

function UdpMock:setsockname(host, port)
    self.peer = {host = host, port = port}
    self.isConnected = true
    self.listen = false
    return 1
end

function UdpMock:setpeername(host, port)
    self.peer = {host = host, port = port}
    self.isConnected = true
    self.listen = true
end

function UdpMock:sendto(packet, ip, port)
    return self:send(packet)
end

function UdpMock:send(packet)
    self.timer:after(
        self.lag,
        function()
            table.insert(self.received, packet)
        end
    )
    return 1
end

function UdpMock:receivefrom()
    return self:receive(), self.peer.host, self.peer.port
end

function UdpMock:receive()
    local packets = self.received -- @fixme: real udp socket returns 1 packet at the time
    self.received = {}
    return packets
end

function UdpMock:update(dt)
    self.timer:update(dt)
    local rnd = love.math.random(100)
    if rnd > 98 then
        self.lag = 0.1
        self.timer:after(
        0.3,
        function()
            self.lag = 0.01
        end
    )
    end
end

return SocketMock
