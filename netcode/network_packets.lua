local Class = require "lib.hump.class"

local MAGIC = config.network.packetMagic
local VERSION = config.network.protocolVersion

local Packet = Class {
    init = function (self, type)
        self.magic = MAGIC
        self.version = VERSION
        self.type = type
    end,
    getHeader = function (self)
        return self.magic .. " " .. self.version .. " " .. self.type
    end,
    getBody = function(self)
        return ""
    end,
    serialize = function(self)
        return self:getHeader() .. self:getBody()
    end
}

local packetTypes = {
    Inputs = 1,
    InputsAck = 2,
    Hello = 3,
    HelloAck = 4,
}

local function reverseMap(map)
    local reversed = {}
    for k, v in pairs(map) do
        reversed[v] = k
    end
    return reversed
end

local function isValidHeader(magic, version)
    return magic == MAGIC and version == VERSION
end

local packets = {
    types = packetTypes,
    idToType = reverseMap(packetTypes),
    deserialize = deserialize,
    Inputs = Class {
        __includes = Packet,
        init = function (self, inputs, startFrame, ackFrame)
            self.ackFrame = ackFrame
            self.startFrame = startFrame
            self.inputs = inputs
            Packet.init(self, packetTypes.Inputs)
        end,
        getBody = function(self)
            local inputs = ""
            for _, it in ipairs(self.inputs) do
                inputs = inputs .. " " .. it.x .. "," .. it.y
            end 
            return " " .. self.ackFrame .. " " .. self.startFrame .. " " .. #self.inputs .. inputs
        end
    },
    InputsAck = Class {
        __includes = Packet,
        init = function (self, ackFrame)
            self.ackFrame = ackFrame
            Packet.init(self, packetTypes.InputsAck)
        end,
        getBody = function(self)
            return " " .. self.ackFrame
        end,
    },
    Hello = Class {
        __includes = Packet,
        init = function (self)
            Packet.init(self, packetTypes.Hello)
        end
    },
    HelloAck = Class {
        __includes = Packet,
        init = function (self)
            Packet.init(self, packetTypes.HelloAck)
        end
    }
}

function packets.deserialize(packet)
    local tokens = {}
    for token in string.gmatch(packet, "[^%s]+") do
        table.insert(tokens, token)
    end
    if not isValidHeader(tokens[1], tokens[2]) then
        print("Got invalid packet: " .. packet)
        return
    end
    local packetType = packets.idToType[tonumber(tokens[3])]
    if packetType and packets[packetType] then
        packet = packets[packetType].fromPacket(tokens)
    end
    return packet
end

function packets.Inputs.fromPacket(tokens)
    local ackFrame = tonumber(tokens[4])
    local startFrame = tonumber(tokens[5])
    local inputs = {}
    local numOfInputs = tonumber(tokens[6])
    local i = 0
    while i < numOfInputs do
        local x, y = string.match(tokens[7+i], "(%w+),(%w+)")
        table.insert(inputs, {x = tonumber(x), y = tonumber(y)})
        i = i + 1
    end
    return packets.Inputs(inputs, startFrame, ackFrame)
end

function packets.InputsAck.fromPacket(tokens)
    local ackFrame = tonumber(tokens[4])
    return packets.InputsAck(ackFrame)
end

return packets