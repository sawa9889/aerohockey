local Class = require "lib.hump.class"

local Packet = Class {
    init = function (self, type)
        self.magic = "AERO"
        self.version = "1"
        self.type = type
    end
}

local packetTypes = {
    inputs = 1,
    inputsAck = 2,
    hello = 3,
    helloAck = 4,
}

local packets = {
    Inputs = Class {
        __includes = Packet,
        init = function (self, inputs, startFrame, ackFrame)
            self.inputs = inputs
            self.startFrame = startFrame
            self.ackFrame = ackFrame
            Packet.init(self, packetTypes.inputs)
        end
    },
    InputsAck = Class {
        __includes = Packet,
        init = function (self, ackFrame)
            self.ackFrame = ackFrame
            Packet.init(self, packetTypes.inputsAck)
        end
    },
    Hello = Class {
        __includes = Packet,
        init = function (self)
            Packet.init(self, packetTypes.hello)
        end
    },
    HelloAck = Class {
        __includes = Packet,
        init = function (self)
            Packet.init(self, packetTypes.helloAck)
        end
    }
}

return packets