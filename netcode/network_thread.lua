-- this is a love thread
-- usage:
-- local networkManagerThread = love.thread.newThread( require "netcode.network_manager" )
-- networkManagerThread:start()
require 'love.timer'
require 'engine.debug'
local log = require 'engine.logger' ("networkSocket", function(msg) return "[netsocket thread]: " .. msg end)

local running = true

local gameInputChannel     = love.thread.getChannel("networkControl")
local networkOutputChannel = love.thread.getChannel("networkOutput")

local socket = require("socket")

local udp, isConnected, peer, listen

local function reset()
    log(2, "SOCKET RESET")
    if udp then
        udp:close()
    end
    udp = socket.udp()
    udp:settimeout(0)
    isConnected = false
    peer = {}
    listen = false
end

reset()

local function sendPacket(packet, ip, port)
    log(4, "Sending packet: <" .. packet .. "> to " .. ip .. ":" .. port )
    local result, msg
    if isConnected then
        result, msg = udp:send(packet)
    else
        result, msg = udp:sendto(packet, ip, port)
    end
    if not result then log(2, "Send error ", result, msg, packet, ip, port) end
end

local function awaitConnection(host, port)
    local result, msg = udp:setsockname(host, port)
    if not result then log(2, "Set sock error ", result, msg, host, port) end
    listen = true
end

local function connect(host, port)
    log(4, "Connecting to ".. host .. ":" .. port )
    udp:setpeername(host, port)
    peer = {host = host, port = port}
    isConnected = true
    listen = true
end

local function receivePackets()
    local packets = {}
    local circuitBreaker = 10
    while circuitBreaker > 0 do
        local data, ipOrMsg, portOrNil
        if isConnected then
            data, ipOrMsg = udp:receive()
        else
            data, ipOrMsg, portOrNil = udp:receivefrom()
        end
        if not data then
            if ipOrMsg ~= "timeout" then
                log(2, "Network error: " .. ipOrMsg)
            end
            break
        end
        
        log(4, "Received packets:")
        log(4, {data = data, ipOrMsg = ipOrMsg, portOrNil = portOrNil})
        if isConnected then
            ipOrMsg = peer.host
            portOrNil = peer.port
        end
        table.insert(packets, { packet = data, ip = ipOrMsg, port = portOrNil })
        circuitBreaker = circuitBreaker - 1
    end
    return packets
end

local function handleTask(task)
    log(5, "Got task: " .. task.command )
    if task.command == "connect" then
        connect(task.host, task.port)
    elseif task.command == "awaitConnection" then
        awaitConnection(task.host, task.port)
    elseif task.command == "send" then
        sendPacket(task.packet, task.ip, task.port)
    elseif task.command == "close" then
        reset()
    end
end

local lastTime = love.timer.getTime()
while running do
    dt = love.timer.getTime() - lastTime
    lastTime = love.timer.getTime()

    -- check if still online
    if listen then
        local received = receivePackets()
        for _, packet in ipairs(received) do
            networkOutputChannel:push( { type = "packet", data = packet } )
        end
    end
    while gameInputChannel:peek() do
        local task = gameInputChannel:pop()
        if task.command then
            handleTask(task)
        end
    end

    love.timer.sleep(0.005)
end
