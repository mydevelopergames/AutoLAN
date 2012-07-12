--THIS CODE IS DESIGNED TO WORK WITH THE QUICK START SERVER, PLEASE OPEN THAT AS WELL
----------------------------------------------------------------------------------------------------------
----------------------------Client Specific Startup-------------------------------------------------------
----------------------------------------------------------------------------------------------------------

local client = require "Client"
client:start()
client:autoConnect()

--the following is called when we send a priority message and when we get confirmation that it was received
local function priorityCallback(e)
	if(e.phase == "complete") then
		print("priority message sent and acknowledged")
	elseif(e.phase == "cancelled") then
		print("message not sent, connection timed out or was closed")
	end
	client:sendPriority("hello world, the time here is"..system.getTimer(), {callback = priorityCallback}) --this will send packets as fast as they are acknowledged
end

----------------------------------------------------------------------------------------------------------
----------------------------Client Specific Listeners-----------------------------------------------------
----------------------------------------------------------------------------------------------------------
local function autolanConnected(event)
	print("broadcast", event.customBroadcast) --this is the user defined broadcast recieved from the server, it tells us about the server state.
	print("serverIP," ,event.serverIP) --this is the user defined broadcast recieved from the server, it tells us about the server state.
	--now that we have a connecton, let us just constantly send stuff to the server as an example
	client:sendPriority("hello world, the time here is"..system.getTimer(), {callback = priorityCallback})
	print("connection established")
end
Runtime:addEventListener("autolanConnected", autolanConnected)

local function autolanServerFound(event)
	print("broadcast", event.customBroadcast) --this is the user defined broadcast recieved from the server, it tells us about the server state.
	print("server name," ,event.serverName) --this is the name of the server device (from system.getInfo()). if you need more details just put whatever you need in the customBrodcast
	print("server IP:", event.serverIP) --this is the server IP, you must store this in an external table to connect to it later
	print("autolanServerFound")
end
Runtime:addEventListener("autolanServerFound", autolanServerFound)

local function autolanDisconnected(event)
	print("disconnected b/c ", event.message) --this can be "closed", "timeout", or "user disonnect"
	print("serverIP ", event.serverIP) --this can be "closed", "timeout", or "user disonnect"
	print("autolanDisconnected") 
end
Runtime:addEventListener("autolanDisconnected", autolanDisconnected)

local function autolanReceived(event)
	print("message = ", event.message) --this is the message we recieved from the server
	print("autolanReceived")
end
Runtime:addEventListener("autolanReceived", autolanReceived)

local function autolanFileReceived(event)
	print("filename = ", event.filename) --this is the filename in the system.documents directory
	print("autolanFileReceived")
end
Runtime:addEventListener("autolanFileReceived", autolanFileReceived)

local function autolanConnectionFailed(event)
	print("serverIP = ", event.serverIP) --this indicates that the server went offline between discovery and connection. the serverIP is returned so you can remove it form your list
	print("autolanConnectionFailed")
end
Runtime:addEventListener("autolanConnectionFailed", autolanConnectionFailed)


