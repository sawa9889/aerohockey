local Timer = require "lib.hump.timer"
require 'love.math'

local UdpMock = {
    timer = Timer.new(),
    lag = 0.01,
    received = {}
}

function UdpMock:send(packet)
    self.timer:after(
        self.lag,
        function()
            table.insert(self.received, packet)
        end
    )
end

function UdpMock:receive()
    local packets = self.received
    self.received = {}
    return packets
end

function UdpMock:update(dt)
    self.timer:update(dt)
    local rnd = love.math.random(100)
    if rnd > 98 then
        self.lag = 0.01
        self.timer:after(
        0.3,
        function()
            self.lag = 0.01
        end
    )
    end
end

return UdpMock
