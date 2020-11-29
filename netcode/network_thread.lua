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

local socket = require("socket")
local udp = socket.udp()
udp:settimeout(0)
-- local socket = require "netcode.udp_mock"

local function sendPacket(packet, ip, port)
    udp:sendto(packet, ip, port)
end

local function awaitConnection(host, port)
    udp:setsockname(host, port)
end

local function getRecievedPackets()
    local packets = {}
    local circuitBreaker = 100
    while circuitBreaker > 0 do
        local data, ipOrMsg, portOrNil = udp:receivefrom()
        if not data then
            if ipOrMsg ~= "timeout" then
                print("Network error: " .. ipOrMsg)
            end
            break
        end
        table.insert(packets, { packet = data, ip = ipOrMsg, port = portOrNil })
        circuitBreaker = circuitBreaker + 1
    end
    return packets
end

local function handleTask(task)
    if task.command == "connect" then
        connect(task.ip, task.port)
    elseif task.command == "awaitConnection" then
        awaitConnection(task.host, task.port)
    elseif task.command == "send" then
        sendPacket(task.packet, ip, port)
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

    love.timer.sleep(0.016)
end
