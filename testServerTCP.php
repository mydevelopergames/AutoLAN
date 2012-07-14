<?php 
require_once('geoplugin.class.php');
$geoplugin = new geoPlugin();	

//ini_set('error_reporting', E_ALL ^ E_NOTICE); 
//ini_set('display_errors', 1); 
ini_set( 'default_socket_timeout', 15);
// Set time limit to indefinite execution 
set_time_limit (0); 

// Set the ip and port we will listen on 
$address = '0.0.0.0'; 
$port = 54613; 

// Create a TCP Stream socket 
$sock = socket_create(AF_INET, SOCK_STREAM, SOL_TCP); 
$sockUDP = socket_create(AF_INET, SOCK_DGRAM, SOL_UDP); 
// Bind the socket to an address/port 
socket_bind($sock, $address, $port) or die('Could not bind to address'); 
socket_bind($sockUDP, $address, $port+1) or die('Could not bind to address'); 
// Start listening for connections 
socket_listen($sock);  
// Non block socket type 
socket_set_nonblock($sock); 
//socket_set_nonblock($sockUDP); 
// Loop continuously 
while (true) 
{ 
    if (@$newsock = socket_accept($sock)) 
    { 
        if (is_resource($newsock)) 
        { 
			// Non block socket type 
			socket_set_nonblock($newsock); 
            socket_getpeername($newsock,$clientIP, $clientPort);

			//use both client ip and port as a key for the array
            $client[$clientIP.$clientPort]["socket"] = $newsock; 
			$client[$clientIP.$clientPort]["ip"] = $clientIP; 
			$client[$clientIP.$clientPort]["port"] = $clientPort; 
			//now get an approximate geolocation of this server/client
			$geoplugin->locate($clientIP);
			$client[$clientIP.$clientPort]["longitude"] = $geoplugin->longitude; 
			$client[$clientIP.$clientPort]["latitude"] = $geoplugin->latitude; 			
            echo "New client connected $j, with ip $clientIP, port $clientPort"."\n"; 
			
        } 
    } 
	
	if (@socket_recvfrom($sockUDP, $string, 999999, MSG_DONTWAIT, $from, $port) === 0) 
	{
	} else {
		while($string){				
			$decoded = json_decode($string);
		//	var_dump($decoded);			
			if($decoded[2] == "cs"){
				//here we inform the target client that UDP packets are on the way and to start listening for these packets.
				echo "got server UDP message $string"."\n";
				socket_sendto($sockUDP, json_encode(array("c", $from, $port))."\n",9999,0,$decoded[3], $decoded[4]); //n for new connection
			}
			elseif($decoded[2] == "cc"){
				//the client is informing us to send a connect signal to the server (first we send via tcp)
				echo "got client UDP message $string"."\n";
				socket_write($client[$decoded[3]]["socket"], json_encode(array("n", $from, $port))."\n"); //n for new connection
			}
			// socket_sendto($sockUDP,$string, strlen($string), 0, $from, $port); //echo back via udp		
			 unset($string);		
			@socket_recvfrom($sockUDP, $string, 999999, MSG_DONTWAIT, $from, $port);
			
		}

	}
	
    if (count($client)) 
    { 
        foreach ($client as $k => &$v) 
        { 

 
			 if (@socket_recv($v["socket"], $strings, 999999, MSG_DONTWAIT) === 0) 
				{ 
				 	echo "connection closed"."\n"; 
					socket_close($v["socket"]); 
					echo "unsetting client $k".count($servers[$v["application"]])."\n";
					unset($servers[$v["application"]][$k]);
					echo "unsetting client $k".$v["application"]."\n";
					unset($client[$k]);
					unset($v); 	
					continue;				
				} 
			else {
				
				foreach(explode("\n", $strings) as $key => $string) {
				
					$decoded = json_decode($string);
					//var_dump($decoded);
					
					//the first packet must tell if we are a client or a server
					if($decoded and $decoded[0] == "CoronaAutoInternet"){
						//decode message type
						if($decoded[2]=="s"){
							//add this to the server list
							$v["application"] = $decoded[1];
							$v["deviceName"] = $decoded[3];
							$v["customBroadcast"] = $decoded[4];
							$servers[$decoded[1]][$k] = $v;  //decoded[1] is the application id
							echo "added to server $string".count($servers[$decoded[1]]).count($servers[$v["application"]])."\n";
						} 
						elseif($decoded[2]=="c"){
							echo "client detected"."\n";
							//this is a client, sort the lists by geographic distance and return a list of servers and close the connection	
							//create a array of distance to all servers with same application id
							$index = 0;
							$clientLat = $v["latitude"];
							$clientLong = $v["longitude"];
							$j = 0;
							foreach ($servers[$decoded[1]] as $key => $server){
								$deltaLat = $server["latitude"] - $clientLat;
								$deltaLong = $server["longitude"] - $clientLong;
								$distanceTable[$key] = $deltaLat*$deltaLat+$deltaLong*$deltaLong;
								//TESTING ONLY send all currently availible servers
								$sendServers[$j++] = array($server["ip"],$server["port"],$server["deviceName"],$server["customBroadcast"]);
							}
							@socket_write($v["socket"], json_encode(array("l",$sendServers))."\n");//l for listing, a list of availible servers to connect to.
							unset($j);
							unset($sendServers);														
							asort($distanceTable);
						}

					}
				}
			}
        } 
    } 

    //echo "."; 

   usleep(1000000); 
} 

// Close the master sockets 
socket_close($sock); 
?>