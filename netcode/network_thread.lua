-- this is a love thread
-- usage:
-- local networkManagerThread = love.thread.newThread( require "netcode.network_manager" )
-- networkManagerThread:start()
require 'love.timer'

local gameState = "menu" -- waiting_for_client, connecting, ready_to_play, playing, disconnected, error
local player = 1 -- 2

local running = true

local gameInputChannel     = love.thread.getChannel("networkControl")
local networkOutputChannel = love.thread.getChannel("networkOutput")

local udpSocket = require "netcode.udp_mock"

local function sendPacket(packet)
    udpSocket:send(packet)
end

local function getRecievedPackets()
    return udpSocket:receive()
end

local function handleTask(task)
    if task.command == "connect" then
        connect(task.ip, task.port)
    elseif task.command == "awaitConnection" then
        awaitConnection(task.port)
    elseif task.command == "send" then
        sendPacket(task.packet)
    elseif task.command == "exit" then
        running = false
    end
end

local lastTime = love.timer.getTime()
while running do
    dt = love.timer.getTime() - lastTime
    lastTime = love.timer.getTime()

    -- check if still online
    recieved = getRecievedPackets()
    for _, packet in ipairs(recieved) do
        networkOutputChannel:push( { type = "packet", data = packet } )
    end
    while gameInputChannel:peek() do
        local task = gameInputChannel:pop()
        if task.command then
            handleTask(task)
        end
    end

    udpSocket:update(dt) -- TODO: del this?
    love.timer.sleep(0.016)
end
