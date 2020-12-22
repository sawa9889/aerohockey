serpent = require "lib.debug.serpent"
Debug = {
    showFps = 0,
    showStatesLoadSave = 0,
    netcodeLog = 0,
    desyncDebugLog = 0,
    netcodeDebugWidget = 0,
    ballSpeedLog = 0,
    replayDebug = 0,
    visualDesyncDebug = 0,
    networkSocket = 0
}

-- usage: vardump(x1, test, myVar) or vardump({ship = self, dt = dt})
vardump = function(...)
    local args = {...}
    print("================VARDUMP=====================")
    if #args == 1 then
        print(serpent.block(args))
    else
        for key, value in pairs(args) do
            if key then print(key..':') end
            print(serpent.block(value))
        end
    end
    print("============================================")
end

return Debug
