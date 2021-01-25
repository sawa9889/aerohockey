Class = require "lib.hump.class"
UiObject = require "engine.ui.uiparents.uiobject"
Button         = require "engine.ui.button"
InputBox       = require "engine.ui.input_box"

MainMenuContainer = Class {
    __includes = UiObject,
    init = function(self, parent)
        UiObject.init(self, love.graphics.getWidth()/4, love.graphics.getHeight()/4, love.graphics.getWidth()/2, love.graphics.getHeight()/2, 'Main Menu')
        local firstLineY, secondLineY, thirdLineY = love.graphics.getHeight()/18, love.graphics.getHeight()/6, love.graphics.getHeight()/3
        local leftColumnX, rightColumnX = love.graphics.getWidth()/10, love.graphics.getWidth()/3.5
        local buttonHeight, buttonWidth = love.graphics.getHeight()/10, love.graphics.getWidth()/6.4
        local inputHeight, inputWidth = love.graphics.getHeight()/10, love.graphics.getWidth()/6.4
        self.parent = parent
        self.windowManager = WindowManager( self.x, self.y, self.width, self.height )
        self.windowManager:registerObject("port_input", InputBox(
            leftColumnX, firstLineY, 
            inputWidth, inputHeight, 
            {
                tag = 'Port',
                defaultText = settings:get("port"),
                position = 'relative',
            }))
        self.windowManager:registerObject("ip_input", InputBox(
            leftColumnX, secondLineY, 
            inputWidth, inputHeight, 
            {
                tag = 'Address',
                defaultText = settings:get("ip"),
                position = 'relative',
            }))
        self.windowManager:registerObject("start_server_btn", Button(
            rightColumnX, firstLineY, 
            buttonWidth, buttonHeight, 
            {
                callback = function() self:startServer() end,
                tag = 'Start server',
                position = 'relative',
            }))
        self.windowManager:registerObject("connect_btn", Button(
            rightColumnX, secondLineY,
            buttonWidth, buttonHeight,
            {
                callback = function() self:connectToGame() end,
                tag = 'Start connect',
                position = 'relative',
            }))
        self.windowManager:registerObject("replay_btn", Button(
            rightColumnX, thirdLineY,
            buttonWidth, buttonHeight,
            {
                callback = function()
                    self.parent.activePage = "Load_Menu"
                end,
                tag = 'Load replay',
                position = 'relative',
            }))
        self.windowManager:registerObject("save_replay_btn", Button(
            leftColumnX, thirdLineY,
            buttonWidth, buttonHeight,
            {
                callback = function()		         
		            if replay.inputs then		        	
		                StateManager.switch(states.replay, require "game", replay, replay.states)
		            end
                end,
                tag = 'Last Replay',
                position = 'relative',
            }))
    end
}

function MainMenuContainer:startServer()
    StateManager.switch(states.connectingState, {
        isServer = true,
        port = self:getPortInput()
    })
end

function MainMenuContainer:connectToGame()
    StateManager.switch(states.connectingState, {
        isServer = false,
        ip = self:getIpInput(),
        port = self:getPortInput()
    })
end

function MainMenuContainer:getIpInput()
    return self.windowManager:getObject("ip_input"):getText()
end

function MainMenuContainer:getPortInput()
    return self.windowManager:getObject("port_input"):getText()
end

function MainMenuContainer:keypressed(t)
    self.windowManager:keypressed(t)
end

function MainMenuContainer:mousepressed(x, y)
    self.windowManager:mousepressed(x, y)
end

-- Указан отдельный объект чтобы логика указанная в Draw была сквозной, а опциональная была в render
function MainMenuContainer:render()
    self:drawBoxAroundObject({r = 0, g = 0, b = 0}, love.graphics.getWidth()/150)
    self.windowManager:draw()
end

function MainMenuContainer:update(dt)
    self.windowManager:update(dt)
end

return MainMenuContainer