-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------
display.setStatusBar( display.HiddenStatusBar )
-- forward declarations
local up,down,left,right, paddleUp, paddleDown, ball, textUp, textDown, client, server, isClient, isServer, myPlayerID
local serverReceived, clientReceived, dragBodyServer, dragBodyClient, ballCollision, sendFullFrame,sendFullFrameTimer, playerDropped, connectionAttemptFailed
local screenW, screenH, halfW, halfH = display.contentWidth, display.contentHeight, display.contentWidth*0.5, display.contentHeight*0.5
local physicsGroup, UIGroup, menuGroup = display.newGroup(), display.newGroup(), display.newGroup()
local upScore, downScore = 0,0
local clients = {} --contains the client objects that represent connections to clients
local physics = require "physics"
physics.start(); physics.setGravity(0,0);  physics.setTimeStep( 1/60 );
local function downHit(e)
	if(e.phase == "began") then
		upScore = upScore+1
		textUp.text = "Score: "..upScore
	end
end
local function upHit(e)
	if(e.phase == "began") then
		downScore = downScore+1
		textDown.text = "Score: "..downScore		
	end
end
local function createScoreDisplay(group)
	textUp = display.newText("Score: 0", 10, 0, native.systemFont, 16)
	textUp:setTextColor(255)	
	textDown = display.newText("Score: 0", 10, screenH-20, native.systemFont, 16)
	textDown:setTextColor(255)		
end
local function createWalls(group)
	--draw walls
	up = display.newRect(group,0,-20,screenW, 20)
	physics.addBody( up, "static", { density=1.0, friction=0, bounce=0} )	
	up:addEventListener("collision", upHit)
	down = display.newRect(group,0,screenH,screenW, 20)
	physics.addBody( down, "static", { density=1.0, friction=0, bounce=0} )	
	down:addEventListener("collision", downHit)	
	left = display.newRect(group,-20,0,20, screenH)
	physics.addBody( left, "static", { density=1.0, friction=0, bounce=0} )	
	right = display.newRect(group,screenW,0,20, screenH)
	physics.addBody( right, "static", { density=1.0, friction=0, bounce=0} )
end
local function createPaddle(group, x, y, rotation)
	local width, height = 120, 30
	local paddle = display.newRoundedRect(group, 0, 0, width, height,10)
	paddle:setReferencePoint(display.CenterReferencePoint)
	paddle.x, paddle.y = x,y
	local shape = {width*.5, -height*.5,	width*.5, height*.1,	width*.4, height*.5,-width*.4, height*.5,-width*.5, height*.1, -width*.5, -height*.5,}
	physics.addBody( paddle, "dynamic", { density=1.0, friction=0, bounce=0, shape = shape} )	
	paddle:rotate(180+rotation)
	paddle.isFixedRotation = true
	paddle:setFillColor(255,100,100)
	paddle.touchJoint = physics.newJoint( "touch", paddle, paddle.x, paddle.y )
	paddle.targetX = x
	function paddle:setTarget(x) 
		self.touchJoint:setTarget(x,self.y)
		self.targetX = x
	end
	return paddle
end
local function createBall(group)
	local puck = display.newCircle( halfW,halfH,20)
	physics.addBody( puck, { density=0, friction=0.3, bounce=1, radius = 20} )
	puck.isBullet = true
	puck:setLinearVelocity(200,200)
	puck:setFillColor(100,255,100)
	group:insert(puck)
	return puck
end

local function makeClient()
	if(isServer) then --if we were a server before, we need to unregister all the event listeners
		paddleDown:setFillColor(255,100,100)
		Runtime:removeEventListener("autolanPlayerDropped", playerDropped)
		Runtime:removeEventListener("autolanPlayerJoined", addPlayer)
		paddleDown:removeEventListener("touch", dragBodyServer) --assign bottom padle to server
		Runtime:removeEventListener("autolanReceived", serverReceived) --all incoming packets sent to serverReceived
		ball:removeEventListener("collision", ballCollision)
		timer.cancel(sendFullFrameTimer)
		isServer = false
	end
	print("making client")
	client = require("Client")
	client:start()
	client:scanServersInternet()
	isClient = true
	Runtime:addEventListener("autolanReceived", clientReceived) --all incoming packets are sent to clientReceived
	Runtime:addEventListener("autolanConnectionFailed", connectionAttemptFailed)
	Runtime:addEventListener("autolanDisconnected", connectionAttemptFailed)	
end
local function makeServer()
	if(isClient) then --if we were a client before, we need to unregister all the event listeners
		isClient = false
		paddleUp:setFillColor(255,100,100)
		Runtime:removeEventListener("autolanReceived", clientReceived) --all incoming packets are sent to clientReceived
		Runtime:removeEventListener("autolanConnectionFailed", connectionAttemptFailed)
		Runtime:removeEventListener("autolanDisconnected", connectionAttemptFailed)	
	end
	server = require("Server")
	server:setCustomBroadcast("1 Player")
	server:startInternet()
	isServer = true
	menuGroup:removeSelf()
	paddleDown:setFillColor(100,100,255)
	--add event listeners
	Runtime:addEventListener("autolanPlayerDropped", playerDropped)
	Runtime:addEventListener("autolanPlayerJoined", addPlayer)
	paddleDown:addEventListener("touch", dragBodyServer) --assign bottom padle to server
	Runtime:addEventListener("autolanReceived", serverReceived) --all incoming packets sent to serverReceived
	ball:addEventListener("collision", ballCollision)
	sendFullFrameTimer = timer.performWithDelay(2000, sendFullFrame, -1)
end
---------------------------UI OBJECTS--------------------
local numberOfServers = 0
local function spawnMenu(group)
	--functions to handle button events
	local joinText 
	local function joinPressed()
		joinText.text = "Scanning..."
		 makeClient()
	end
	local function hostPressed()
		makeServer()
	end
	local title = display.newRoundedRect(group, 0, 0, screenW*.8,60,20)
	title:setReferencePoint(display.CenterReferencePoint)
	title.x,title.y = halfW, 50
	title:setFillColor(100,100,100)
	local titleText = display.newText(group, "Multiplayer Pong", 0, 0, native.systemFont, 24)
	titleText:setReferencePoint(display.CenterReferencePoint)
	titleText.x, titleText.y = halfW, 50
	--host button
	local host = display.newRoundedRect(group, 20, 100, 120,60,20)
	host:setFillColor(100,100,100)
	host:addEventListener("tap", hostPressed)
	local hostText = display.newText(group, "Host", 50, 115, native.systemFont, 24)
	--host button
	local join = display.newRoundedRect(group, 160, 100, 120,60,20)
	join:addEventListener("tap", joinPressed)
	join:setFillColor(100,100,100)	
	joinText = display.newText(group, "Join", 195, 115, native.systemFont, 24)


	local function createListItem(event) --displays found servers
		local item = display.newGroup()
		item.background = display.newRoundedRect(item,20,0,screenW-50,60,20)
		item.background.strokeWidth = 3
		item.background:setFillColor(70, 70, 70)
		item.background:setStrokeColor(180, 180, 180)
		item.text = display.newText(item,event.serverName.."    "..event.customBroadcast, 40, 20, "Helvetica-Bold", 18 )
		if(event.internet) then
			item.text:setTextColor( 100,100,255 )
		else
			item.text:setTextColor( 255 )
		end
		item.serverIP = event.serverIP		
		--attach a touch listener
		function item:tap(e)
			client:connect(self.serverIP)
			menuGroup:removeSelf()
			menuGroup = nil
		end
		item:addEventListener("tap", item)
		
		item.y = numberOfServers*70+180
		numberOfServers = numberOfServers+1
		menuGroup:insert(item)
	end
	Runtime:addEventListener("autolanServerFound", createListItem)
	
end
----create the scene-------------------
createWalls(physicsGroup)
paddleDown = createPaddle(physicsGroup, halfW, screenH*.95, 0)
paddleUp = createPaddle(physicsGroup, halfW, screenH*.05, 180)
ball = createBall(physicsGroup)
createScoreDisplay(UIGroup)
spawnMenu(menuGroup)

local speed = 350
local function setBallSpeed()
	if(ball) then
	if(speed < 500) then
		speed = speed+.1
	end
	--get the direction and set the speed
	vx,vy  = ball:getLinearVelocity()
	local direction = math.atan2(vy,vx)
	ball:setLinearVelocity(math.cos(direction)*speed, math.sin(direction)*speed)
	end
end
Runtime:addEventListener("enterFrame", setBallSpeed)

----------------------------------------------------------------------------------------------
-------------------------------------SERVER SPECIFIC CODE-------------------------------------
----------------------------------------------------------------------------------------------
local numPlayers = 0
local clients = {}
local function getFullGameState()
	local state = {}
	state[1] = 2--protocol id
	state[2] = paddleUp.targetX
	state[3] = paddleDown.targetX
	state[4] = ball.x
	state[5] = ball.y
	vx, vy = ball:getLinearVelocity()
	state[6] = vx
	state[7] = vy
	state[8] = upScore
	state[9] = downScore
	return state
end
local function getDifferentialGameState()
	local state = {}
	state[1] = 4--protocol id
	state[2] = paddleUp.targetX
	state[3] = paddleDown.targetX
	return state
end
local function getBallState()
	local state = {}
	state[1] = 5--protocol id
	state[2] = ball.x
	state[3] = ball.y
	vx, vy = ball:getLinearVelocity()
	state[4] = vx
	state[5] = vy
	return state
end
playerDropped = function(event)
	local clientDropped = event.client
	--go through the table and find the client that dropped
	for i=1, numPlayers do
		if(clients[i] == clientDropped) then
			table.remove(clients, i) --remove this client
			numPlayers = numPlayers - 1
		end
	end
	server:setCustomBroadcast(numPlayers.." Players")
	--now let us try to find a spectator client to retake control of the paddle
	if(clients[1]) then
		clients[1]:sendPriority({1,1}) --initialization packet with playerID = 1 so client can control paddle
	end
	print("player dropped because", event.message)
end
addPlayer = function(event)
	local client = event.client --this is the client object, used to send messages
	print("player joined",client)
	--look for a client slot
	numPlayers = numPlayers+1
	clients[numPlayers] = client
	client:sendPriority({1,numPlayers}) --initialization packet
	client:sendPriority(getFullGameState()) --initialization packet	
	server:setCustomBroadcast(numPlayers.." Players")
end
ballCollision = function(event)
	if(event.phase == "ended") then
		--send ball update packet to all clients
		for i=1, numPlayers do
			clients[i]:send(getBallState())
		end		
	end
end
sendFullFrame = function()
	for i=1, numPlayers do
		clients[i]:send(getFullGameState())
	end	
end
serverReceived =  function(event)
	local message = event.message
	--since this message came from a client, it can only be of type 3: player update
	paddleUp:setTarget(message[2])
	--now forward a differential update to all clients (some are spectators)
	for i=1, numPlayers do
		clients[i]:send(getDifferentialGameState())
	end
end

dragBodyServer = function(e)
	local body = e.target
	body.touchJoint:setTarget(e.x, body.y)
	body.targetX = e.x
	if "began" == e.phase then
		display.getCurrentStage():setFocus( body, e.id )
	elseif "ended" == e.phase or "cancelled" == e.phase then
		display.getCurrentStage():setFocus( body, nil )
	elseif "moved" ==e.phase then
		--now forward a differential update to all clients (some are spectators)
		for i=1, numPlayers do
			clients[i]:send(getDifferentialGameState())
		end	
	end
end

----------------------------------------------------------------------------------------------
-------------------------------------CLIENT SPECIFIC CODE-------------------------------------
----------------------------------------------------------------------------------------------

connectionAttemptFailed = function(event)
	print("connection failed, redisplay menu")
	numberOfServers = 0
	menuGroup = display.newGroup()
	spawnMenu(menuGroup)
end

local function connectedToServer(event)
	print("connected, waiting for sync")
end
Runtime:addEventListener("autolanConnected", connectedToServer)

local function getPlayerUpdate()
	local state = {}
	state[1] = 4--protocol id
	state[2] = paddleUp.targetX
	return state
end
dragBodyClient = function(e)
	local body = e.target
	body.touchJoint:setTarget(e.x, body.y)
	body.targetX = e.x
	if "began" == e.phase then
		display.getCurrentStage():setFocus( body, e.id )
	elseif "ended" == e.phase or "cancelled" == e.phase then
		display.getCurrentStage():setFocus( body, nil )
	elseif "moved" ==e.phase then
		--now forward an update to the server
		client:send(getPlayerUpdate())
	end
end
local function restoreBallState(message)
	local dx, dy = message[2]-ball.x, message[3]-ball.y
	ball:translate(dx,dy)
	ball:setLinearVelocity(message[4],message[5])
end
local ballControl = false
local function restoreGameState(message)
	paddleUp:setTarget(message[2])
	paddleDown:setTarget(message[3])	
	ball.x, ball.y = message[4], message[5]
	ball:setLinearVelocity(message[6],message[7])
	upScore,  downScore = message[8], message[9]
	textUp.text = "Score: "..upScore	
	textDown.text = "Score: "..downScore
end
clientReceived = function (event)
	local message = event.message
	print("message", message, message[1], message[2])
	--figure out packet type
	if(message[1] == 1) then
		print("got init packet")
		if(message[2] == 1) then --we are the first player to join, let us take control of the ball
			paddleUp:addEventListener("touch", dragBodyClient)
			paddleUp:setFillColor(100,100,255)
			ballControl = true
		end
	elseif(message[1] == 2) then
		restoreGameState(message)
	elseif(message[1] == 4) then	
		print("got differential packet",message[2],message[3])
		paddleDown:setTarget(message[3])
		if(not ballControl) then
			paddleUp:setTarget(message[2])
		end
	elseif(message[1] == 5) then
		print("got ball update packet")
		restoreBallState(message)
	end
end
