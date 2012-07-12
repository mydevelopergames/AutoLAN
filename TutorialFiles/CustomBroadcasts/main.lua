--THIS CODE IS DESIGNED TO WORK WITH THE QUICK START CLIENT, PLEASE OPEN THAT AS WELL
----------------------------------------------------------------------------------------------------------
----------------------------Server Specific Startup-------------------------------------------------------
----------------------------------------------------------------------------------------------------------

local server = require "Server"
server:start()
server:setCustomBroadcast("0 Players")
---and thats it! you will be notified when a connection is availible in the event listener and you will also start receiving data in the listeners.
local clients = {} --table to store all of our client objects.
local numClients = 0

--lets just send stuff to all our clients
local function sendStuff()
	for i,client in pairs(clients) do
		client:send("this server has been up for"..system.getTimer())
	end
end
Runtime:addEventListener("enterFrame", sendStuff)
----------------------------------------------------------------------------------------------------------
----------------------------Server Specific Listeners-----------------------------------------------------
----------------------------------------------------------------------------------------------------------
local function autolanPlayerJoined(event)
	local client = event.client
	--print("client object: ", client) --this represents the connection to the client. you can use this to send messages and files to the client. You should save this in a table somewhere.
	--now lets save the client object so we can use it in the future to send messages
	clients[client] = client --trick, we can use the table object itself as the key, this will make it easier to determine which client we received a message from
	numClients = numClients + 1
	client.myJoinTime = system.getTimer() --you can add whatever values you want to the table to retrieve it later in the receved listener
	client.myName = "Player "..numClients
	--now let us update the custom broadcast to reflect the new server state
	server:setCustomBroadcast(numClients .. " Players")
	print("autolanPlayerJoined") 
end
Runtime:addEventListener("autolanPlayerJoined", autolanPlayerJoined)

local function autolanPlayerDropped(event)
	local client = event.client
	print("client object ", client) --this is the reference to the client object you use to send messages to the client, you can use this to findout who dropped and react accordingly
	print("dropped b/c ," ,event.message) --this is the user defined broadcast recieved from the server, it tells us about the server state.
	--now let us remove the client from our list
	print(clients[client].myName.." Dropped, connection was active for "..system.getTimer()-clients[client].myJoinTime)
	clients[client] = nil --clear references to prevent memory leaks
	numClients = numClients - 1	
	--now let us update the custom broadcast to reflect the new server state
	server:setCustomBroadcast(numClients .. " Players")
end
Runtime:addEventListener("autolanPlayerDropped", autolanPlayerDropped)

local function autolanReceived(event)
	local client = event.client
	print("Message :"..event.message.." from client: "..client.myName ) --myName is our own property set in the playerJoined event
	--we can use the client object here to react to the message
	--client:send("Recieved it!, thanks!")
end
Runtime:addEventListener("autolanReceived", autolanReceived)

local function autolanFileReceived(event)
	print("filename = ", event.filename) --this is the filename in the system.documents directory
	print("autolanFileReceived")
end
Runtime:addEventListener("autolanFileReceived", autolanFileReceived)