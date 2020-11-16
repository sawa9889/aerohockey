local Timer = require "lib.hump.timer"

local UdpMock = {
    timer = Timer.new(),
    received = {}
}

function UdpMock:send(packet)
    self.timer:after(
        0.01,
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
end

return UdpMock
