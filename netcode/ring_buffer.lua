local Class = require "lib.hump.class"

local RingBuffer = Class {
    init = function(self, maxSize)
        self.elements = {}
        self.head = 1
        self.size = maxSize
    end
}

function RingBuffer:push(item)
    self.elements[self.head] = item
    self.head = self.head + 1
    if self.head > self.size then
        self.head = 1
    end
end

function RingBuffer:peek()
    return self.elements[self.head]
end

function RingBuffer:pop()
    self.head = self.head - 1
    if self.head < 1 then
        self.head = self.size
    end
    return self.elements[self.head]
end

return RingBuffer
