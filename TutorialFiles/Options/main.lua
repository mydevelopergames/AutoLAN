server:setOptions{applicationName = "someUniqueName"}
client:setOptions{applicationName = "someUniqueName"}
----------------------------------------------------------------------------------------------------------
----------------------------Client Specific Options-------------------------------------------------------
----------------------------------------------------------------------------------------------------------
function client:setOptions(params)
	timeoutTime = params.timeoutTime or timeoutTime --number of ms to wait before the server is considered dead
	applicationName = params.applicationName or applicationName --the name of the application. set this to prevent other autoLAN applications from discovering you	
	circularBufferSize = params.circularBufferSize or circularBufferSize --number of elements to store in the circular buffer for high priority messages and files
	packetSize = params.packetSize or packetSize --size of packets for files
end
----------------------------------------------------------------------------------------------------------
----------------------------Server Specific Options-------------------------------------------------------
----------------------------------------------------------------------------------------------------------
function server:setOptions(params)
	broadcastTime = params.broadcastTime or broadcastTime --number of milliseconds between UDP broadcasts for network discovery
	applicationName = params.applicationName or applicationName --the name of the application. set this to prevent other autoLAN applications from discovering you
	customBroadcast = params.customBroadcast or customBroadcast --custom broadcast, tells clients about the state of the server
	connectTime = params.connectTime or connectTime --frequency to look for new clients
	timeoutTime = params.timeoutTime or timeoutTime --number of cycles to wait before client is DC
	circularBufferSize = params.circularBufferSize or circularBufferSize --max number of elements in circular buffer for high priorirty messages and files
	packetSize = params.packetSize or packetSize --size of packets for files
end