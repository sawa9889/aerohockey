require 'engine.debug'

local function getLogger(name, converter)
    if not converter then
        converter = function (it) return it end
    end
    return function (level, ...)
        if not Debug or not Debug[name] or Debug[name] < level then
            return
        end
        local message = {...}
        if #message == 1 and message[1] then
            message = message[1]
            if type(message) == "string" then
                print(converter(message))
                return
            end
            print(converter(serpent.block(message)))
            return
        end
        for key, value in pairs(message) do
            if key then print(key..':') end
            print(converter(serpent.block(value)))
        end
    end
end

return getLogger
