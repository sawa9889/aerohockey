Class = require "lib.hump.class"
UiObject = require "engine.ui.uiparents.uiobject"

MainMenuContainer = Class {
    __includes = UiObject,
    init = function(self, parent, parameters)
        UiObject.init(self, parent, parameters)
        self:registerObject("Start_server_button", 
                                     {row = 2, column = 3}, 
                                     Button(self, {  
                                        tag = 'Start server', 
                                        width = 200, 
                                        height = 50, 
                                        background = AssetManager:getImage('experimental_button'),
                                        callback = function(obj, x, y) self:startServer() end
                                    }))
        self:registerObject("start_connection_button", 
                                         {row = 3, column = 3}, 
                                         Button(self, {  
                                            tag = 'Start connection', 
                                            width = 200, 
                                            height = 50, 
                                            background = AssetManager:getImage('experimental_button'),
                                            callback = function(obj, x, y) self:connectToGame() end
                                        }))
        self:registerObject("show_last_replay_button", 
                                         {row = 4, column = 2}, 
                                         Button(self, {  
                                            tag = 'Show replay', 
                                            width = 200, 
                                            height = 50, 
                                            background = AssetManager:getImage('experimental_button'),
                                            callback = function(obj, x, y) 
                                                            if replay.inputs then                    
                                                                StateManager.switch(states.replay, require "game", replay, replay.states)
                                                            end 
                                                        end
                                        }))
        self:registerObject("show_saved_replays_button", 
                                         {row = 4, column = 3}, 
                                         Button(self, {  
                                            tag = 'Show saved replays', 
                                            width = 200, 
                                            height = 50, 
                                            background = AssetManager:getImage('experimental_button'),
                                            callback = function(obj, x, y) 
                                                            self.parent.activePage = "Load_Menu"
                                                        end
                                        }))
        self:registerObject("ip_adress_input", 
                                         {row = 2, column = 2}, 
                                         InputBox(self, {  
                                            tag = 'Ip address', 
                                            width = 200, 
                                            height = 50, 
                                            background = AssetManager:getImage('field'),
                                            defaultText = settings:get("ip")
                                        }))
        self:registerObject("port_input", 
                                         {row = 3, column = 2}, 
                                         InputBox(self, {  
                                            tag = 'Port', 
                                            width = 200, 
                                            height = 50, 
                                            background = AssetManager:getImage('field'),
                                            defaultText = settings:get("port")
                                        }))
    end
}

function MainMenuContainer:startServer()
    StateManager.switch(states.connectingState, {
        isServer = true,
        ip = self:getIpInput(), -- it's not necessary, but connection state saves this to settings
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
    return self.objects['ip_adress_input'].object:getText()
end

function MainMenuContainer:getPortInput()
    return self.objects["port_input"].object:getText()
end

return MainMenuContainer