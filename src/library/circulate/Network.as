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
    import flash.utils.Timer;
    
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
        public static function getDefaultConfiguration():NetworkConfiguration
        {
            var config:NetworkConfiguration;
                config = new NetworkConfiguration();
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
        
        public static function serialize( command:* ):Packet
        {
            if( !(command is NetworkCommand) )
            {
                trace( command + " is not a NetworkCommand" );
                return null;
            }
            
            var netcmd:NetworkCommand = command as NetworkCommand;
            
            var data:ByteArray = new ByteArray();
                data.writeObject( command );
                data.position = 0;
                data.compress();
            
            var packet:Packet = new Packet( data );
            return packet;
        }
        
        public static function deserialize( packet:Packet ):* //any NetworkCommand
        {
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
        
        
        private var _config:NetworkConfiguration;
        private var _type:NetworkType;
        
        private var _enableErrorChecking:Boolean;
        private var _afterAnalysis:Boolean;
        
        private var _connection:NetConnection;
        private var _nodes:Vector.<NetworkNode>;
        private var _commandCenter:CommandCenter;
        
        private var _timer:Timer;
        
        
        public function Network( type:NetworkType = null , config:NetworkConfiguration = null )
        {
            if( !type ) { type = NetworkType.local; }
            if( !config ) { config = Network.getDefaultConfiguration(); }
            
            _warnAboutServerKey();
            
            _config              = config;
            _type                = type;
            _enableErrorChecking = _config.enableErrorChecking;
            _afterAnalysis       = false;
            
            _nodes               = new Vector.<NetworkNode>();
            
            _timer               = new Timer( _config.connectionTimeout );
        }
        
        //--- events ---
        
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
        
        public function onNetStatus( event:NetStatusEvent ):void
        {
            var code:String   = event.info.code;
            var reason:String = "";
            
            //trace( dump( event, true ) );
            trace( "network netstatus code: " + event.info.code );
            
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
                onGroupConnect( event.info.group );
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
            
            _info( "peer ID = " + _connection.nearID );
            _createCommandCenter();
            
            dispatchEvent( new NetworkEvent( NetworkEvent.CONNECTED ) );
            
            if( _config.connectionTimeout > 0 )
            {
                trace( "use a timeout of " + _config.connectionTimeout + "ms" );
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
            
        }
        
        private function onGroupDisconnect( netgroup:NetGroup, message:String = "" ):void
        {
            
        }
        
        private function onNeighborConnect( peerID:String, address:String ):void
        {
            
        }
        
        private function onNeighborDisconnect( peerID:String, address:String ):void
        {
            
        }
        
        
        //--- private ---
        
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
            trace( _getTypeNetwork() + " network : " +  message );
        }
        
        private function _warn( message:String ):void
        {
            if( !enableErrorChecking )
            {
                trace( "## WARNING : " +  message + " ##" );
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
                trace( "## ERROR : " +  message + " ##" );
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
        
        private function _findNode( name:String ):NetworkNode
        {
            var i:uint;
            var n:NetworkNode;
            
            for( i=0; i<_nodes.length; i++ )
            {
                n = _nodes[i];
                
                trace( "node name = [" + n.name + "]" );
                trace( "     name = [" + name + "]" );
                
                if( n.name == name ) { return n; }
            }
            
            return null;
        }
        
        private function _createCommandCenter():void
        {
            createNode( config.commandCenter, NodeType.command );
        }
        
        public function createNode( name:String, type:NodeType = null ):void
        {
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
                    node = new CommandCenter( this, name );
                    _commandCenter = node as CommandCenter;
                    break;
                    
//                    case NodeType.chat:
//                    node = new ChatNode( this, name );
//                    break;
                    
//                    case NodeType.swarm:
//                    node = new SwarmNode( this );
//                    break;
                    
//                    case NodeType.onefile:
//                    node = new OneFileNode( this );
//                    break;
                }
                
                _nodes.push( node );
                node.join();
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