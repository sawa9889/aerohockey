-- This is gamestate

local aerohockeyGame = require "game"

local Menu = {

}

function Menu:enter(prevState, game)
end

function Menu:update(dt)
end

function Menu:keypressed(key, scancode, isrepeat)
    if key == "1" then
        StateManager.switch(states.netgame, aerohockeyGame, true)
    end
    if key == "2" then
        StateManager.switch(states.netgame, aerohockeyGame, false)
    end
    if key == "r" then
        if replay.inputs then
            StateManager.switch(states.replay, require "game", replay.inputs, replay.states)
        end
    end
end

function Menu:draw()
    love.graphics.print("Press \"1\" to start server\nPress \"2\" to connect to game\nPress \"R\" to load a replay")
end

return Menu