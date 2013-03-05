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
    import library.circulate.commands.SystemMessage;
    import library.circulate.events.NetworkEvent;
    import library.circulate.nodes.ChatNode;
    import library.circulate.nodes.CommandCenter;
    import library.circulate.nodes.OneFileNode;
    import library.circulate.nodes.SwarmNode;
    import library.circulate.utils.getLocalUserName;
    import library.circulate.utils.traceConnectivityResults;
    import library.circulate.utils.traceNetworkInterfaces;

    /**
    * A Network is responsible for creating, connecting and managing Nodes.
    * Can be associated with only one NetConnection.
    * 
    * note:
    * for now we are managing only 1 network which can be of different types
    * local, test server, adobe server 
    */
    public class Network extends EventDispatcher
    {
        //--- static ---
        
        public static function getDefaultConfiguration():NetworkConfiguration
        {
            var config:NetworkConfiguration;
                config = new NetworkConfiguration();
                config.loopback              = true;
                config.enableErrorChecking   = false;
                config.compressPacket        = true;
                config.wrapCommandIntoPacket = true;
                config.username              = getLocalUserName();
                config.localArea             = "rtmfp:";
                config.testServer            = "cc.rtmfp.net";
                config.adobeServer           = "p2p.rtmfp.net";
                config.serverKey             = ""; //you do need to provide your key
                config.commandCenter         = "library.circulate.commandcenter";
                config.IPMulticastAddress    = "224.0.0.255:30000";
                config.maxPeerConnections    = 32;
                config.connectionTimeout     = 0; //0 means no timeout
            
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
        
        public static function serialize( command:NetworkCommand, useCompression:Boolean = false ):Packet
        {
            var data:ByteArray = new ByteArray();
                data.writeObject( command );
                data.position = 0;
                
                if( useCompression )
                {
                    data.compress();
                    data.position = 0;
                }
            
            var packet:Packet = new Packet( data );
            return packet;
        }
        
        public static function deserialize( packet:Packet, useCompression:Boolean = false ):NetworkCommand
        {
            if( packet == null ) { return null; }
            
            if( useCompression )
            {
                packet.data.position = 0;
                packet.data.uncompress();
            }
            
            packet.data.position = 0;
            
            var command:* = packet.data.readObject();
            
            if( command is NetworkCommand )
            {
                //deserialize as a NetworkCommand
                return command;
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
        
        private function onNetStatus( event:NetStatusEvent ):void
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
                onNodeConnect( event.info.group as NetGroup );
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
                onNodeDisconnect( event.info.group as NetGroup, reason.toLowerCase() );
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
        
        private function onNodeConnect( netgroup:NetGroup ):void
        {
            _log( "network.onNodeConnect()" );
            
            var node:NetworkNode = _findNodeByGroup( netgroup );
            
            if( node )
            {
                //we add the local client to the list of clients
                node.addLocalClient();
                
                if( node.group.estimatedMemberCount == 1 )
                {
                    _log( "you are alone in node " + node.name );
                    
                    if( node != _commandCenter )
                    {
                        var username:String = client.username;
                        var peerID:String   = client.peerID;
                        var date:Date = new Date();
                        var str:String = "<{user}> joined [{node}] @ {date}";
                        var msg:String = format( str, {user:username,node:node.name,date:date.toString()} );
                        
                        var syscmd:NetworkCommand = new SystemMessage( msg, peerID );
                        sendCommandToNode( syscmd, _commandCenter );
                    }
                }
                
            }
            
        }
        
        private function onNodeDisconnect( netgroup:NetGroup, message:String = "" ):void
        {
            _log( "network.onNodeDisconnect()" );
            
            var node:NetworkNode = _findNodeByGroup( netgroup );
            
            if( node )
            {
                //we remove the local client to the list of clients
                node.removeLocalClient();
            }
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
        
        
        //--- public ---
        
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
        public function get nodes():Vector.<NetworkNode> { return _nodes; }
        public function get commandCenter():NetworkNode { return _commandCenter; }
        
        public function get estimatedTotalMember():uint
        {
            var estimated:uint = 0;
            var i:uint;
            var node:NetworkNode;
            
            for( i=0; i<_nodes.length; i++ )
            {
                node = _nodes[ i ];
                estimated += node.group.estimatedMemberCount;
            }
            
            return estimated;
        }
        
        public function get knownTotalMember():uint
        {
            var known:uint = 0;
            var i:uint;
            var node:NetworkNode;
            
            for( i=0; i<_nodes.length; i++ )
            {
                node = _nodes[ i ];
                known += node.clients.length;
            }
            
            return known;
        }
        
        /**
        * Connect to the network.
        */
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
        
        /**
        * Disconnect from the network.
        */
        public function disconnect():void
        {
            if( _connection )
            {
                _connection.close();
            }
        }
        
        /**
        * Create a NetworkNode.
        * 
        * If the Node aready exists we just join it.
        * If the NodeType is not specified, by default we create a Chat node.
        * 
        * When the NEtwork is initialized we create by default a CommandCenter,
        * if lateryou try to create a NodeType.command with a different name
        * it will fail as youcan only have ONE CommandCenter.
        */
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
                    if( !_commandCenter )
                    {
                        trace( "CREATE NodeType.command" );
                        node = new CommandCenter( this, name );
                        _commandCenter = node as CommandCenter;
                    }
                    else
                    {
                        trace( "CommandCenter already exists, we can only have one" );
                        joinNode( _commandCenter.name );
                        return;
                    }
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
        
        public function sendCommandToNode( command:NetworkCommand, node:NetworkNode = null ):void
        {
            if( !connected )
            {
                _info( "you need to connect first before sending a message to a node." );
                return;
            }
            
            if( !node && (command is ChatMessage) )
            {
                var chatmsg:ChatMessage = command as ChatMessage;
                if( chatmsg.nodename != "" )
                {
                    var node2:NetworkNode = _findNode( chatmsg.nodename );
                    if( node2 )
                    {
                        node = node2;
                    }
                }
            }
            
            if( node )
            {
                node.sendToAll( command );
            }
            else if( _commandCenter )
            {
                //if no Node, we use by default the CommandCenter node
                _commandCenter.sendToAll( command );
            }
            else
            {
                _log( "could not find a Node to send the command [" + command.name + "]" );
                _log( "commandCenter = " + _commandCenter );
            }
            
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