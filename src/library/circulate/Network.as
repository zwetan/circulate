/*
Version: MPL 1.1/GPL 2.0/LGPL 2.1

The contents of this file are subject to the Mozilla Public License Version
1.1 (the "License"); you may not use this file except in compliance with
the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
for the specific language governing rights and limitations under the
License.

The Original Code is [circulate library].

The Initial Developers of the Original Code are
Zwetan Kjukov <zwetan@gmail.com> and Marc Alcaraz <ekameleon@gmail.com>.
Portions created by the Initial Developers are Copyright (C) 2013
the Initial Developers. All Rights Reserved.

Contributor(s):

Alternatively, the contents of this file may be used under the terms of
either the GNU General Public License Version 2 or later (the "GPL"), or
the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
in which case the provisions of the GPL or the LGPL are applicable instead
of those above. If you wish to allow use of your version of this file only
under the terms of either the GPL or the LGPL, and not to allow others to
use your version of this file under the terms of the MPL, indicate your
decision by deleting the provisions above and replace them with the notice
and other provisions required by the LGPL or the GPL. If you do not delete
the provisions above, a recipient may use your version of this file under
the terms of any one of the MPL, the GPL or the LGPL.
*/

package library.circulate
{
    import core.assert;
    import core.dump;
    import core.strings.endsWith;
    import core.strings.format;
    import core.strings.startsWith;
    
    import flash.events.EventDispatcher;
    import flash.events.NetStatusEvent;
    import flash.events.TimerEvent;
    import flash.net.GroupSpecifier;
    import flash.net.NetConnection;
    import flash.net.NetGroup;
    import flash.net.ObjectEncoding;
    import flash.utils.ByteArray;
    import flash.utils.Dictionary;
    import flash.utils.Timer;
    
    import library.circulate.clients.Client;
    import library.circulate.commands.ChatMessage;
    import library.circulate.commands.ConnectNetwork;
    import library.circulate.commands.JoinNode;
    import library.circulate.events.NetworkEvent;
    import library.circulate.nodes.ChatNode;
    import library.circulate.nodes.CommandCenter;
    import library.circulate.nodes.OneFileNode;
    import library.circulate.nodes.SwarmNode;
    import library.circulate.utils.getLocalUserName;
    import library.circulate.utils.traceConnectivityResults;
    import library.circulate.utils.traceNetworkInterfaces;

    /**
    * A Network is responsible for creating, connecting and managing Nodes and Clients.
    * Can be associated with only one NetConnection.
    * 
    * note:
    * for now we are managing only 1 network whcih can be of different types
    * local, test server, adobe server 
    */
    public class Network extends EventDispatcher
    {
        //--- static ---
        
        public static function getDefaultConfiguration():NetworkConfiguration
        {
            var config:NetworkConfiguration;
                config = new NetworkConfiguration();
                config.loopback            = true;
                config.enableErrorChecking = false;
                config.username            = getLocalUserName();
                config.localArea           = "rtmfp:";
                config.testServer          = "cc.rtmfp.net";
                config.adobeServer         = "p2p.rtmfp.net";
                config.serverKey           = ""; //you do need to provide your key
                config.commandCenter       = "library.circulate.commandcenter";
                config.IPMulticastAddress  = "224.0.0.255:30000";
                config.maxPeerConnections  = 32;
                config.connectionTimeout   = 0; //0 means no timeout
            
            return config;
        }
        
        public static function getDefaultGroupSpecifier( name:String, multicast:String ):GroupSpecifier
        {
            var groupspec:GroupSpecifier = new GroupSpecifier( name );
                groupspec.ipMulticastMemberUpdatesEnabled = true;
                groupspec.objectReplicationEnabled        = true;
                groupspec.multicastEnabled                = true;
                groupspec.postingEnabled                  = true;
                groupspec.routingEnabled                  = true;
                groupspec.addIPMulticastAddress( multicast );
            
            return groupspec;
        }
        
        public static function serialize( command:NetworkCommand ):Packet
        {
//            if( !(command is NetworkCommand) )
//            {
//                //_log( command + " is not a NetworkCommand" );
//                return null;
//            }
//            
//            var netcmd:NetworkCommand = command as NetworkCommand;
            
            var data:ByteArray = new ByteArray();
                data.writeObject( command );
                data.position = 0;
                data.compress();
                data.position = 0;
            
            var packet:Packet = new Packet( data );
            return packet;
        }
        
        public static function deserialize( packet:Packet ):NetworkCommand //any NetworkCommand
        {
            packet.data.position = 0;
            packet.data.uncompress();
            packet.data.position = 0;
            
            var command:* = packet.data.readObject();
            
            if( command is NetworkCommand )
            {
                //deserialize a NetworkCommand
                return command;
            }
            
            //deserializer did not found a NetworkCommand
            return null;
        }
        
        public static function deserialize2( packet:* ):* //any NetworkCommand
        {
            if( packet && packet.data )
            {
                packet.data.uncompress();
                packet.data.position = 0;
                
                var command:* = packet.data.readObject();
                
                if( command is NetworkCommand )
                {
                    //deserialize a NetworkCommand
                    return command;
                }
            }
            
            //deserializer did not found a NetworkCommand
            return null;
        }
        
        
        //--- --- --- --- --- --- --- --- ---
        
        
        private var _type:NetworkType;
        private var _config:NetworkConfiguration;
        
        private var _enableErrorChecking:Boolean;
        private var _afterAnalysis:Boolean;
        
        private var _connection:NetConnection;
        private var _commandCenter:CommandCenter;
        private var _local:Client;
        
        private var _nodes:Vector.<NetworkNode>;
        private var _clients:Vector.<NetworkClient>;
        
        private var _timer:Timer;
        
        public var writer:Function;
        
        public function Network( type:NetworkType = null , config:NetworkConfiguration = null )
        {
            if( !type ) { type = NetworkType.local; }
            if( !config ) { config = Network.getDefaultConfiguration(); }
            
            _type                = type;
            _config              = config;
            _enableErrorChecking = _config.enableErrorChecking;
            _afterAnalysis       = false;
            
            _nodes               = new Vector.<NetworkNode>();
            _clients             = new Vector.<NetworkClient>();
            
            _local               = new Client( _config.username );
            _timer               = new Timer( _config.connectionTimeout );
            
            writer               = trace;
        }
        
        //--- events ---
        
        public function onNetStatus( event:NetStatusEvent ):void
        {
            var code:String   = event.info.code;
            var reason:String = "";
            
            //trace( dump( event, true ) );
            _log( "network netstatus code: " + event.info.code );
            
            switch( code )
            {
                
                /* ---- NetConnection ---- */
                
                /* The connection attempt succeeded. */
                case "NetConnection.Connect.Success": // event.info.motd 
                onConnect( event.info.motd );
                break;
                
                
                /* The server-side application is shutting down. */
                case "NetConnection.Connect.AppShutdown":
                
                /* The connection was closed successfully. */
                case "NetConnection.Connect.Closed":
                
                /* The connection attempt failed. */
                case "NetConnection.Connect.Failed":
                _warnAboutServerKey();
                
                /* The application name specified in the call to NetConnection.connect() is invalid. */
                case "NetConnection.Connect.InvalidApp":
                
                /* The connection attempt did not have permission to access the application. */
                case "NetConnection.Connect.Rejected":
                
                if( _afterAnalysis )
                {
                    _afterAnalysis = false;
                    _info( "closing ..." );
                }
                
                reason = code.split( "." ).pop();
                onDisconnect( reason.toLowerCase() );
                break;
                
                /* Flash Media Server disconnected the client because the client was idle longer
                   than the configured value for <MaxIdleTime>.
                   On Flash Media Server, <AutoCloseIdleClients> is disabled by default.
                   When enabled, the default timeout value is 3600 seconds (1 hour).
                   For more information, see Close idle connections.
                */
                case "NetConnection.Connect.IdleTimeout":
                break;
                
                /* Flash Player has detected a network change,
                   for example, a dropped wireless connection,
                   a successful wireless connection,or a network cable loss.
                */
                case "NetConnection.Connect.NetworkChange":
                onNetworkChange();
                break;
                
                /* ---- NetConnection (custom) ---- */
                
                /* diagnostic results from cc.rtmfp.net
                   not officially supported
                */
                case "NetConnection.ConnectivityCheck.Results":
                onConnectivityCheckResults( event.info );
                break;
                
                
                /* ---- NetGroup ---- */
                
                /* The NetGroup is successfully constructed and authorized to function.
                   The info.group property indicates which NetGroup has succeeded.
                */
                case "NetGroup.Connect.Success": // event.info.group
                _log( "--- NetGroup.Connect.Success ---" );
                onGroupConnect( event.info.group as NetGroup );
                break;
                
                /* The NetGroup connection attempt failed.
                   The info.group property indicates which NetGroup failed.
                */
                case "NetGroup.Connect.Failed": // event.info.group
                
                /* The NetGroup is not authorized to function.
                   The info.group property indicates which NetGroup was denied.
                */
                case "NetGroup.Connect.Rejected": // event.info.group
                reason = code.split( "." ).pop();
                onGroupDisconnect( event.info.group, reason.toLowerCase() );
                break;
                
                /* Sent when a neighbor connects to this node.
                   The info.neighbor:String property is the group address of the neighbor.
                   The info.peerID:String property is the peer ID of the neighbor.
                */
                case "NetGroup.Neighbor.Connect": // event.info.neighbor, event.info.peerID
                onNeighborConnect( event.info.peerID, event.info.neighbor );
                break;
                
                /* Sent when a neighbor disconnects from this node.
                   The info.neighbor:String property is the group address of the neighbor.
                   The info.peerID:String property is the peer ID of the neighbor.
                */
                case "NetGroup.Neighbor.Disconnect": // event.info.neighbor, event.info.peerID
                onNeighborDisconnect( event.info.peerID, event.info.neighbor );
                break;
                
                /* Sent when a message directed to this node is received.
                   The info.message:Object property is the message.
                   The info.from:String property is the groupAddress from which the message was received.
                   The info.fromLocal:Boolean property is TRUE if the message was sent by this node
                   (meaning the local node is the nearest to the destination group address),
                   and FALSE if the message was received from a different node.
                   To implement recursive routing, the message must be resent with NetGroup.sendToNearest() 
                   if info.fromLocal is FALSE.
                */
                case "NetGroup.SendTo.Notify": // event.info.message, event.info.from, event.info.fromLocal
                onSendToNotify( event.info.from, event.info.message, event.info.fromLocal );
                break;
                
                /* Sent when a new Group Posting is received.
                   The info.message:Object property is the message.
                   The info.messageID:String property is this message's messageID.
                */
                case "NetGroup.Posting.Notify": // event.info.message, event.info.messageID
                onPostingNotify( event.info.messageID, event.info.message );
                //onPostingNotify2( event );
                break;
                
            }
            
        }
        
        private function onTimeout( event:TimerEvent ):void
        {
            _timer.removeEventListener( TimerEvent.TIMER_COMPLETE, onTimeout );
            
            _info( "Connection timed out after " + _config.connectionTimeout + "ms" );
            disconnect();
        }
        
        
        //--- netstatus actions ---
        
        private function onConnect( motd:String = "" ):void
        {
            _info( "connected" );
            
            if( (motd != "") && (motd != null) )
            {
                _info( ">> motd: " + motd + " <<" );
            }
            
            _local.peerID = _connection.nearID;
            _info(  _local + " (peer ID = " + _local.peerID + ")" );
            _createCommandCenter();
            
            dispatchEvent( new NetworkEvent( NetworkEvent.CONNECTED ) );
            
            if( _config.connectionTimeout > 0 )
            {
                _log( "use a timeout of " + _config.connectionTimeout + "ms" );
                _startTimeout();
            }
        }
         
        private function onDisconnect( message:String = "" ):void
        {
            _info( "disconnected - " + message );
            dispatchEvent( new NetworkEvent( NetworkEvent.DISCONNECTED ) );
        }
        
        private function onConnectivityCheckResults( info:Object ):void
        {
            _info( "received connectivity results" );
            traceConnectivityResults( info, _info );
            _afterAnalysis = true;
        }
        
        private function onNetworkChange():void
        {
            traceNetworkInterfaces( _info );
            
        }
        
        private function onGroupConnect( netgroup:NetGroup ):void
        {
            _log( "---- Group Connect ----" );
            var node:NetworkNode = _findNodeByGroup( netgroup );
            
            if( node )
            {
                _log( "name: " + node.name );
                _log( "type: " + node.type.toString() );
                _log( "members: " + node.group.estimatedMemberCount );
            }
            else
            {
                _error( "Could not find Node for " + netgroup );
            }
        }
        
        private function onGroupDisconnect( netgroup:NetGroup, message:String = "" ):void
        {
            
        }
        
        private function onNeighborConnect( peerID:String, address:String ):void
        {
            _log( "---- Neighbor Connect ----" );
            var node:NetworkNode = _findNodeByPeerIDAndAddress( peerID, address );
            
            if( !_hasClient( peerID ) )
            {
                var client:NetworkClient = new Client( "", peerID );
                _addClient( client );
            }
            
            if( node )
            {
                _log( "peer ID: " + peerID );
                _log( "joined " + node.name );
                _log( "type: " + node.type.toString() );
                _log( "members: " + node.group.estimatedMemberCount );
                //_findClientByPeerID( peerID );
                
//                _log( "group connect -> join node" );
//                var cmd:NetworkCommand = new JoinNode( _local.username, _local.peerID );
//                sendCommandToNode( cmd, node );
//                
////                if( node.type == NodeType.chat )
////                {
//                    _log( "group connect -> chat message" );
//                    var chat:ChatMessage = new ChatMessage( "hello world", node.name );
//                    sendCommandToNode( chat, node );
////                }

//                if( node.type == NodeType.command )
//                {
                    var now:Date = new Date();
                    var timestamp:uint = now.valueOf();
                    var cmd:NetworkCommand = new ConnectNetwork( _local.username, _local.peerID, timestamp )
//                }
            }
            else
            {
                _error( "Could not find Node for " + peerID );
            }
            
        }
        
        private function onNeighborDisconnect( peerID:String, address:String ):void
        {
            var node:NetworkNode = _findNodeByPeerIDAndAddress( peerID, address );
            
            if( _hasClient( peerID ) )
            {
                var client:NetworkClient = _findClientByPeerID( peerID );
                var index:uint = _findClientIndex( client );
                _removeClient( index );
            }
            
            if( node )
            {
                _log( "peer ID: " + peerID );
                _log( "left " + node.name );
            }
        }
        
        private function onPostingNotify2( event:NetStatusEvent ):void
        {
            var netgroup:NetGroup = event.target as NetGroup;
//            _log( "netgroup = " + netgroup );
            var id:String = event.info.messageID;
//            _log( "id = " + id );
            var message:Object = event.info.message;
//            _log( "message = " + message );
            
            var packet:Packet = message as Packet;
//            _log( "packet = " + packet );
//            _log( "  |_ id: " + packet.id );
//            _log( "  |_ data: " + packet.data );
//            _log( "" );
            
            var cmd:NetworkCommand = Network.deserialize( packet );
//            _log( "cmd = " + cmd );
            
            if( cmd )
            {
                _interpretCommands( cmd );
            }
        }
        
        private function onPostingNotify( id:String, message:Object ):void
        {
/*
		private function handlePosting(event:NetStatusEvent):void
		{
			var message:MessageVO = event.info.message as MessageVO;
				
			if (!message)
				return;
			
			var group:NetGroup = event.target as NetGroup; 
			var groupInfo:GroupInfo = groups[group];
			
			if (message.type == CommandType.SERVICE) 
			{
				if (message.command == CommandList.ANNOUNCE_NAME) 
				{
					for each (var client:ClientVO in groupInfo.clients) 
					{
						if(client.groupID == message.client.groupID) 
						{
							client.clientName = message.client.clientName;
							dispatchEvent(new ClientEvent(ClientEvent.CLIENT_UPDATE, client, group));
							break;
						}
					}
				}
				else if (message.command == CommandList.ANNOUNCE_SHARING)
				{
					dispatchEvent(new ObjectEvent(ObjectEvent.OBJECT_ANNOUNCED, message.data as ObjectMetadataVO));
				}
				else if (message.command == CommandList.REQUEST_OBJECT)
				{
					dispatchEvent(new ObjectEvent(ObjectEvent.OBJECT_REQUEST, message.data as ObjectMetadataVO));
				}
				else if (message.command == CommandList.ACCELEROMETER)
				{
					dispatchEvent(new MessageEvent(MessageEvent.DATA_RECEIVED, message, group));
				}
			} 
			else 
			{
				dispatchEvent(new MessageEvent(MessageEvent.DATA_RECEIVED, message, group));
			}
		}	
*/
            _log( "received packet via POST" );
            _log( "id = " + id );
//            _log( "message = " + message );
            
            var packet:Packet = message as Packet;
//            _log( "packet = " + packet );
//            _log( "  |_ id: " + packet.id );
//            _log( "  |_ data: " + packet.data );
//            _log( "" );
            
            var cmd:NetworkCommand;
            
            if( packet )
            {
                cmd = Network.deserialize( packet );
            }
            else
            {
                _log( "packet is null" );
            }
//            _log( "cmd = " + cmd );
            
            if( cmd )
            {
                _interpretCommands( cmd );
            }
            else
            {
                _log( "cmd is null" );
            }
        }
        
        private function onSendToNotify( address:String, message:Object, isLocal:Boolean = false ):void
        {
            _log( "received packet via SEND" );
            
            var packet:Packet = message as Packet;
            _log( "packet = " + packet );
            _log( "  |_ id: " + packet.id );
            _log( "  |_ data: " + packet.data );
            _log( "" );
            
            var cmd:NetworkCommand;
            
            if( packet )
            {
                cmd = Network.deserialize( packet );
            }
            else
            {
                trace( "packet is null" );
            }
//            _log( "cmd = " + cmd );
            
            if( cmd )
            {
                _interpretCommands( cmd );
            }
            else
            {
                trace( "cmd is null" );
            }
            
        }
        
        
        private function _interpretCommands( cmd:NetworkCommand ):void
        {
//            _log( ">>> interpreting command" );
//            _log( "is network command: " + (cmd is NetworkCommand) );
//            _log( "command [" + cmd.name + "]" );
            
            var client:NetworkClient;
            
            switch( cmd.type )
            {
                case CommandType.connectNetwork:
                var command0:ConnectNetwork = cmd as ConnectNetwork;
                _log( "command [" + command1.name + "]" );
                _log( "  |_ username: " + command0.username );
                _log( "  |_ peerID: " + command0.peerID );
                _log( "  |_ timestamp: " + command0.timestamp );
                
                client = _findClientByPeerID( command0.peerID );
                var date:Date = new Date( command0.timestamp );
                if( client && (client.username == "") )
                {
                    client.username = command0.username;
                }
                
                _log( "[system] : <" + client.username + "> connected to [" + _getTypeNetwork() + " network] @ " + date.toString()  );
                
                break;
                
                case CommandType.joinNode:
                var command1:JoinNode = cmd as JoinNode;
                _log( "command [" + command1.name + "]" );
                _log( "  |_ username: " + command1.username );
                _log( "  |_ peerID: " + command1.peerID );
                
                client = _findClientByPeerID( command1.peerID );
                if( client && (client.username == "") )
                {
                    client.username = command1.username;
                    _log( "[system] : " + client.username + " arrived" );
                }
                break;
                
                case CommandType.chatMessage:
                var command2:ChatMessage = cmd as ChatMessage;
                _log( "command [" + command2.name + "]" );
                _log( "  |_ message: " + command2.message );
                _log( "  |_ nodename: " + command2.nodename );
                break;
                
                default:
                _error( "command [" + cmd.type + "] could not be interpreted" );
            }
            
            
//            switch( cmd.type )
//            {
//                case CommandType.chatMessage:
//                var command:ChatMessage = cmd as ChatMessage;
//                _log( "[command center] - received [ChatMessage] from \"\"" );
//                //trace( "command is [ChatMessage] = " + (command is ChatMessage) );
//                //trace( command.user + ": " + command.message );
//                //_log( command.user + ": " + command.message );
//                break;
//                
//                default:
//                //trace( "command type notfound" );
//                _error( "command \"" + cmd.type + "\" could not be interpreted" );
//            }
        }
        
        //--- private ---
        
        private function _log( message:String ):void
        {
            writer( message );
        }
        
        private function _warnAboutServerKey():void
        {
            if( (type == NetworkType.internet) && (config.serverKey == "") )
            {
                _warn( NetworkStrings.serverKeyEmpty );
            }
        }
        
        private function _startTimeout():void
        {
            _timer.addEventListener( TimerEvent.TIMER_COMPLETE, onTimeout );
            _timer.delay       = _config.connectionTimeout;
            _timer.repeatCount = 1;
            _timer.start();
        }
        
        private function _getTypeNetwork():String
        {
            if( type )
            {
                return type.toString();
            }
            
            return "unknown";
        }
        
        private function _info( message:String ):void
        {
            _log( _getTypeNetwork() + " network : " +  message );
        }
        
        private function _warn( message:String ):void
        {
            if( !enableErrorChecking )
            {
                _log( "## WARNING : " +  message + " ##" );
            }
        }
        
        private function _error( message:String ):void
        {
            if( enableErrorChecking )
            {
                throw new Error( message );
            }
            else
            {
                _log( "## ERROR : " +  message + " ##" );
            }
        }
        
        
        public function get config():NetworkConfiguration { return _config; }
        public function set config( value:NetworkConfiguration ):void { _config = value; } //make it read-only ?
        
        public function get type():NetworkType { return _type; }
        
        /** Specifies whether errors encountered by the network are reported to the application. */
        public function get enableErrorChecking():Boolean { return _enableErrorChecking; }
        public function set enableErrorChecking( value:Boolean ):void { _enableErrorChecking = value; }
        
        public function get connection():NetConnection { return _connection; }
        
        public function get connected():Boolean
        {
            if( _connection )
            {
                return _connection.connected;
            }
            
            return false;
        }
        
        public function get client():NetworkClient { return _local; }
        public function get clients():Vector.<NetworkClient> { return _clients; }
        
        public function get nodes():Vector.<NetworkNode> { return _nodes; }
        
        public function connect( server:String = "", key:String = "" ):void
        {
            if( server == "" )
            {
                switch( type )
                {
                    case NetworkType.test:
                    server = "rtmfp://" + config.testServer;
                    break;
                    
                    case NetworkType.internet:
                    server = "rtmfp://" + config.adobeServer;
                    key    = config.serverKey;
                    break;
                    
                    case NetworkType.local:
                    default:
                    server = config.localArea;
                    break;
                }
                
            }
            else if( server == config.localArea )
            {
                _type = NetworkType.local;
            }
            else
            {
                if( !startsWith( server, "rtmfp://" ) )
                {
                    server = "rtmfp://" + server;
                }
                
                if( endsWith( server, "/" ) )
                {
                    server = server.substr( 0, server.length-1 );
                }
                
                if( server.indexOf( config.testServer ) > -1 )
                {
                    _type = NetworkType.test;
                }
                else
                {
                    _type = NetworkType.internet;
                    
                    if( key == "" )
                    {
                        key = config.serverKey;
                    }
                    
                }
            }
            
            if( (server != "") && (key != "") && (type == NetworkType.internet) )
            {
                server += "/" + key + "/";
            }
            
            if( !connected )
            {
                _info( format( NetworkStrings.networkConnectingTo, {server:server} ) );
                
                _connection = new NetConnection();
                _connection.maxPeerConnections = config.maxPeerConnections;
                _connection.objectEncoding     = ObjectEncoding.AMF3; // we don't want this to be overridable 
                
                _connection.addEventListener( NetStatusEvent.NET_STATUS, onNetStatus );
                _connection.connect( server );
                
            }
        }
        
        public function disconnect():void
        {
            if( _connection )
            {
                _connection.close();
            }
        }
        
        private function _createCommandCenter():void
        {
            createNode( config.commandCenter, NodeType.command );
        }
        
        private function _addNode( node:NetworkNode ):void
        {
            _nodes.push( node );
        }
        
        private function _removeNode( index:uint ):void
        {
            _nodes.splice( index, 1 );
        }
        
        private function _findNode( name:String ):NetworkNode
        {
            var i:uint;
            var node:NetworkNode;
            for( i = 0; i<_nodes.length; i++ )
            {
                node = _nodes[ i ];
                
                if( node.name == name )
                {
                    return node;
                }
            }
            
            return null;
        }
        
        private function _findNodeByGroup( netgroup:NetGroup ):NetworkNode
        {
            var i:uint;
            var node:NetworkNode;
            for( i = 0; i<_nodes.length; i++ )
            {
                node = _nodes[ i ];
                
                if( node.group == netgroup )
                {
                    return node;
                }
            }
            
            return null;
        }
        
        private function _findNodeByPeerIDAndAddress( peerID:String, address:String ):NetworkNode
        {
            var i:uint;
            var node:NetworkNode;
            var groupaddress:String;
            
            for( i=0; i<_nodes.length; i++ )
            {
                node = _nodes[i];
                groupaddress = node.group.convertPeerIDToGroupAddress( peerID );
                
                if( groupaddress == address )
                {
                    return node;
                }
            }
            
            return null;
        }
        
        
        private function _addClient( client:NetworkClient ):void
        {
            _clients.push( client );
        }
        
        private function _removeClient( index:uint ):void
        {
            _clients.splice( index, 1 );
        }
        
        private function _hasClient( peerID:String ):Boolean
        {
            if( !connected ) { return false; }
            
            if( _nodes.length == 0 ) { return false; }
            
            var client:NetworkClient = _findClientByPeerID( peerID );
            
            if( client )
            {
                return true;
            }
            
            return false;
        }
        
        private function _findClientByPeerID( peerID:String ):NetworkClient
        {
            var i:uint;
            var client:NetworkClient;
            
            for( i=0; i<_clients.length; i++ )
            {
                client = _clients[i];
                
                if( client.peerID == peerID )
                {
                    return client;
                }
            }
            
            return null;
        }
        
        private function _findClientIndex( client:NetworkClient ):uint
        {
            var i:uint;
            var c:NetworkClient;
            
            for( i=0; i<_clients.length; i++ )
            {
                c = _clients[i];
                
                if( c == client )
                {
                    return i;
                }
            }
            
            return null;
        }
        
        public function createNode( name:String, type:NodeType = null ):void
        {
            _log( ">>> creating Node \""+ name +"\"");
            if( !connected )
            {
                _info( "you need to connect first before joining a node." );
                return;
            }
            
            if( !type ) { type = NodeType.chat; } 
            
            if( hasNode( name ) )
            {
                joinNode( name );
            }
            else
            {
                var node:NetworkNode;
                
                switch( type )
                {
                    case NodeType.command:
                    trace( "CREATE NodeType.command" );
                    node = new CommandCenter( this, name );
                    _commandCenter = node as CommandCenter;
                    break;
                    
                    case NodeType.chat:
                    trace( "CREATE NodeType.chat" );
                    node = new ChatNode( this, name );
                    break;
                    
//                    case NodeType.swarm:
//                    node = new SwarmNode( this );
//                    break;
                    
//                    case NodeType.onefile:
//                    node = new OneFileNode( this );
//                    break;
                }
                
                if( node )
                {
                    _addNode( node );
                    node.join();
                }
                else
                {
                    _error( "can not create this type of Node: " + type.toString() );
                }
            }
        }
        
        public function hasNode( name:String ):Boolean
        {
            if( !connected ) { return false; }
            
            if( _nodes.length == 0 ) { return false; }
            
            var node:NetworkNode = _findNode( name );
            
            if( node )
            {
                return true;
            }
            
            return false;
        }
        
        public function joinNode( name:String ):void
        {
            var node:NetworkNode = _findNode( name );
            
            if( node )
            {
                node.join();
            }
            else
            {
                _log( "Could not join Node \"" + name + "\"" );
            }
        }
        
        public function leaveNode( name:String ):void
        {
            var node:NetworkNode = _findNode( name );
            
            if( node )
            {
                node.leave();
            }
            else
            {
                _log( "Could not leave Node \"" + name + "\"" );
            }
        }
        
        private function _sendPacketToNode( packet:Packet, node:NetworkNode ):void
        {
            var messageID:String = node.group.post( packet );
            
            if( messageID == null )
            {
                _log( "message was not sent - not received message ID" );
            }
            else
            {
                _log( "message " + messageID + " sent." );
                //onPostingNotify( messageID, packet );
            }
        }
        
        public function sendCommandToNode( command:NetworkCommand, node:NetworkNode = null ):void
        {
            if( !node && _commandCenter )
            {
                node = _commandCenter;
            }
            else
            {
                _log( "could not find a Node to send the command" );
                return;
            }
            
            //_log( "sending command [" + command.name + "]" );
//            _log( "sending command: " + command );
//            _log( "to node: \"" + node.name + "\" (" + node.type + ")" );
            
            var p:Packet = Network.serialize( command );
//            _log( "packet " + p.id + " : data " + p.data.length + " bytes" ); 
            _sendPacketToNode( p, node );
        }
        
        public function resetTimeout():void
        {
            if( connected )
            {
                _timer.reset();
            }
        }
        
    }
}