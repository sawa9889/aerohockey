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
    SpectatorInputs = 6,
    SpectatorInputsAck = 7,
    Hello = 3,
    HelloAck = 4,
    Disconnect = 5,
    StartGame = 8
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
    SpectatorInputs = Class {
        __includes = Packet,
        init = function (self, inputs, startFrame, ackFrame)
            self.ackFrame = ackFrame
            self.startFrame = startFrame
            self.inputs = inputs
            Packet.init(self, packetTypes.SpectatorInputs)
        end,
        getBody = function(self)
            local inputs = ""
            for _, it in ipairs(self.inputs) do
                inputs = inputs .. " " .. it[1].x .. "," .. it[1].y .. "," .. it[2].x .. "," .. it[2].y
            end 
            return " " .. self.ackFrame .. " " .. self.startFrame .. " " .. #self.inputs .. inputs
        end
    },
    SpectatorInputsAck = Class { -- @todo: maybe not use x2 number of packets, and put ackFrame to Inputs?
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
    },
    Disconnect = Class {
        __includes = Packet,
        init = function (self)
            Packet.init(self, packetTypes.Disconnect)
        end
    },
    StartGame = Class{
        __includes = Packet,
        init = function (self, playerType)
            self.playerType = playerType
            Packet.init(self, packetTypes.StartGame)
        end,
        getBody = function(self)
            return " " .. self.playerType
        end
    }
}

function packets.deserialize(packet)
    local tokens = {}
    for token in string.gmatch(packet, "[^%s]+") do
        table.insert(tokens, token)
    end
    if not isValidHeader(tokens[1], tokens[2]) then
        error("Got invalid header")
    end
    local packetType = packets.idToType[tonumber(tokens[3])]
    if packetType and packets[packetType] then
        if packets[packetType].fromPacket then
            packet = packets[packetType].fromPacket(tokens)
        else
            packet = packets[packetType]()
        end
    else
        error("Unrecognized packet type: " .. tokens[3])
    end
    return packet
end

function packets.Inputs.fromPacket(tokens)
    local ackFrame = tonumber(tokens[4])
    local startFrame = tonumber(tokens[5])
    local inputs = {}
    local numOfInputs = tonumber(tokens[6])
    if not ackFrame or not startFrame or not numOfInputs or numOfInputs <= 0 or ackFrame < 0 or startFrame < 0 then
        error("Input packet is malformed")
    end
    local i = 0
    while i < numOfInputs do
        local x, y = string.match(tokens[7+i], "(%w+),(%w+)")
        x = tonumber(x)
        y = tonumber(y)
        if not x or not y then
            error("Input sequence is malformed")
        end
        table.insert(inputs, {x = x, y = y})
        i = i + 1
    end
    return packets.Inputs(inputs, startFrame, ackFrame)
end

function packets.SpectatorInputs.fromPacket(tokens)
    local ackFrame = tonumber(tokens[4])
    local startFrame = tonumber(tokens[5])
    local inputs = {}
    local numOfInputs = tonumber(tokens[6])
    if not ackFrame or not startFrame or not numOfInputs or numOfInputs < 0 or ackFrame < 0 or startFrame < 0 then
        error("Input packet is malformed")
    end
    local i = 0
    while i < numOfInputs do
        local x1, y1, x2, y2 = string.match(tokens[7+i], "(%w+),(%w+),(%w+),(%w+)")
        x1 = tonumber(x1)
        y1 = tonumber(y1)
        x2 = tonumber(x2)
        y2 = tonumber(y2)
        if not x1 or not y1 or not x2 or not y2 then
            error("Input sequence is malformed")
        end
        table.insert(inputs, {[1] = {x = x1, y = y1}, [2] = {x = x2, y = y2}})
        i = i + 1
    end
    return packets.SpectatorInputs(inputs, startFrame, ackFrame)
end

function packets.SpectatorInputsAck.fromPacket(tokens)
    local ackFrame = tonumber(tokens[4])
    if not ackFrame or ackFrame < 0 then
        error("Input Ack packet is malformed")
    end
    return packets.InputsAck(ackFrame)
end

function packets.StartGame.fromPacket(tokens)
    local playerType = tokens[4]
    if not playerType or (playerType ~= "player" and playerType ~= "spectator") then
        error("StartGame packet is malformed")
    end
    return packets.StartGame(playerType)
end

return packets