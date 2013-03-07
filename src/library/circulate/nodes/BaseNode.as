package library.circulate.nodes
{
    import core.strings.format;
    
    import flash.events.NetStatusEvent;
    import flash.net.GroupSpecifier;
    import flash.net.NetGroup;
    import flash.net.NetGroupReceiveMode;
    import flash.net.NetGroupSendMode;
    import flash.net.NetGroupSendResult;
    import flash.utils.Dictionary;
    
    import library.circulate.AutomaticDistributedElection;
    import library.circulate.Network;
    import library.circulate.NetworkClient;
    import library.circulate.NetworkCommand;
    import library.circulate.NetworkNode;
    import library.circulate.NetworkStrings;
    import library.circulate.NodeType;
    import library.circulate.Packet;
    import library.circulate.clients.Client;
    import library.circulate.commands.ChatMessage;
    import library.circulate.commands.JoinNode;
    
    /**
    * A Node is responsible for creating, connecting and managing Clients.
    * Can be associated with only one NetGroup or NetStream.
    * 
    * This is the Base class for all NetworkNode.
    */
    public class BaseNode implements NetworkNode
    {
        protected var FULLMESH:uint      = 14;
        
        protected var _type:NodeType     = null;
        protected var _name:String       = "";
        protected var _joined:Boolean    = false;
        protected var _isElected:Boolean = false;
        
        protected var _network:Network;
        protected var _group:NetGroup;
        protected var _specifier:GroupSpecifier;
        
        private var _clients:Vector.<NetworkClient>;
        
        public function BaseNode( network:Network, name:String = "", specifier:GroupSpecifier = null )
        {
            if( !specifier )
            {
                specifier = Network.getDefaultGroupSpecifier( name, network.config.IPMulticastAddress );
            }
            
            _network   = network;
            _name      = name;
            _specifier = specifier;
            
            _clients   = new Vector.<NetworkClient>();
            
            _log( "Node.ctor( \"" + name + "\" )" );
        }
        
        //--- events ---
        
        private function onNetStatus( event:NetStatusEvent ):void
        {
            var code:String   = event.info.code;
            var reason:String = "";
            
            //trace( dump( event, true ) );
            
//            _log( _type.toString() + " [" + name + "]"  + " netstatus code: " + event.info.code );
            
            _log( "Node.onNetStatus( " + event.info.code + " )" );
            
            switch( code )
            {
                
                /* ---- NetGroup ---- */
                
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
                
                /* Sent when a portion of the group address space for
                   which this node is responsible changes.
                */
                case "NetGroup.LocalCoverage.Notify":
                onLocalCoverageNotify();
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
                break;
                
            }
            
        }
        
        
        //--- netstatus actions ---
        
        private function onNeighborConnect( peerID:String, address:String ):void
        {
            _log( "Node.onNeighborConnect( " + peerID + ", " + address + " )" );
            
            _addNeighbour( peerID );
            
            var now:Date = new Date();
            var timestamp:uint = now.valueOf();
            var client:NetworkClient = _network.client;
            var cmd:NetworkCommand = new JoinNode( client.username, client.peerID, timestamp );
            
            //sendToNearest( cmd, address );
            //sendToAllNeighbors( cmd );
            //sendToNeighbor( cmd, NetGroupSendMode.NEXT_INCREASING );
            
            if( estimatedMemberCount <= FULLMESH )
            {
                sendToAllNeighbors( cmd );
            }
            else if( estimatedMemberCount > FULLMESH )
            {
                sendToNeighbor( cmd, NetGroupSendMode.NEXT_INCREASING );
            }
            
        }
        
        private function onNeighborDisconnect( peerID:String, address:String ):void
        {
            _log( "Node.onNeighborDisconnect( " + peerID + ", " + address + " )" );
            
            var client:NetworkClient = _findClientByPeerID( peerID );
            var index:uint = _findClientIndex( client );
            
            _removeClient( index );
            
        }
        
        private function onLocalCoverageNotify():void
        {
            _log( "Node.onLocalCoverageNotify()" );
            
            _runElection();
        }
        
        private function _runElection():void
        {
			var rangeFrom:String = _group.localCoverageFrom;
			var rangeTo:String   = _group.localCoverageTo;
			var election:Boolean = AutomaticDistributedElection.triangulate( rangeFrom, rangeTo );
			
            if( election != _isElected )
            {
                _log( "Election change: " + (election ? "elected" : "not elected") );
            }
            
            _isElected = election;
            _log( "isElected = " + _isElected );
        }
        
        private function onPostingNotify( id:String, message:Object ):void
        {
            _log( "Node.onPostingNotify( " + id + ", " + message + " )" );
            
            var packet:Packet;
            var cmd:NetworkCommand;
            
            if( _network.config.wrapCommandIntoPacket ||
               (message is Packet) )
            {
                packet = message as Packet;
                cmd = Network.deserialize( packet, _network.config.compressPacket );
            }
            else
            {
                cmd = message as NetworkCommand;
            }
            
            if( cmd )
            {
                cmd.execute( _network, this );
            }
            else
            {
                /* note:
                   While testing the first message sent
                   is always resolvedto "null" (strange, bug?)
                */
                _log( "cmd is null" );
            }
            
        }
        
        private function onSendToNotify( address:String, message:Object, isLocal:Boolean = false ):void
        {
            _log( "Node.onSendToNotify( " + address + ", " + message + ", " + isLocal + " )" );
            
            var packet:Packet;
            var cmd:NetworkCommand;
            
            if( _network.config.wrapCommandIntoPacket ||
               (message is Packet) )
            {
                packet = message as Packet;
                cmd = Network.deserialize( packet, _network.config.compressPacket );
            }
            else
            {
                cmd = message as NetworkCommand;
            }
            
            if( cmd )
            {
                if( isLocal )
                {
                    _log( "LOCAL" );
                    return;
                }
                
                cmd.execute( _network, this );
                //sendToNeighbor( cmd, NetGroupSendMode.NEXT_DECREASING );
                //sendToNearest( cmd, address );
            }
            else
            {
                _log( "cmd is null" );
                var empty:NetworkCommand = new ChatMessage( "", address, "", "" );
                //sendToAll( empty );
                sendToAllNeighbors( empty );
            }
            
        }
        
        
        //--- private ---
        
        private function _log( message:String ):void
        {
            var log:Function = _network.writer;
            log( message );
        }
        
        private function _addClient( client:NetworkClient ):void
        {
            _log( "Node._addClient( " + client + " )" );
            
            if( client == _network.client )
            {
                _log( "add local client" );
            }
            
            var test:uint = _findClientIndex( client );
            if( test )
            {
                _log( "client already exists" );
            }
            
            _clients.push( client );
        }
        
        private function _removeClient( index:uint ):void
        {
            _log( "Node._removeClient( " + index + " )" );
            
            _clients.splice( index, 1 );
        }
        
        private function _findClientByPeerID( peerID:String ):NetworkClient
        {
            _log( "Node._findClientByPeerID( " + peerID + " )" );
            
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
            _log( "Node._findClientIndex( " + client + " )" );
            
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
        
        private function _addLocalClient():void
        {
            _log( "Node._addLocalClient()" );
            
            _addClient( _network.client );
            _joined = true;
        }
        
        private function _removeLocalClient():void
        {
            _log( "Node._removeLocalClient()" );
            
            var client:NetworkClient = _network.client;
            var index:uint = _findClientIndex( client );
            _removeClient( index );
            _joined = false;
        }
        
        private function _addNeighbour( peerID:String ):void
        {
            _log( "Node._addNeighbour( " + peerID + " )" );
            
            var client:NetworkClient = _findClientByPeerID( peerID );
            
            if( !client )
            {
                client = new Client( "", peerID );
            }
            
            _addClient( client );
        }
        
        //--- public ---
        
        public function get type():NodeType { return _type; }
        public function get name():String { return _name; }
        public function get specificier():GroupSpecifier { return _specifier; }
        public function get group():NetGroup { return _group; }
        public function get joined():Boolean { return _joined; }
        public function get isElected():Boolean { return _isElected; }
        
        public function get clients():Vector.<NetworkClient> { return _clients; }
        
        public function get estimatedMemberCount():uint
        {
            if( _group )
            {
                return uint( _group.estimatedMemberCount );
            }
            
            return 0;
        }
        
        public function findClientByPeerID( peerID:String ):NetworkClient
        {
            _log( "Node.findClientByPeerID( " + peerID + " )" );
            
            return _findClientByPeerID( peerID );
        }
        
        public function join( password:String = "" ):void
        {
            _log( "Node.join( " + password + " )" );
            
            if( _joined || _group )
            {
                var message:String = format( NetworkStrings.groupAlreadyJoined, {name:name} );
//                trace( message );
                return;
            }
            
            if( password != "" )
            {
                _group = new NetGroup( _network.connection, _specifier.groupspecWithAuthorizations() );
            }
            else
            {
                _group = new NetGroup( _network.connection, _specifier.groupspecWithoutAuthorizations() );
            }
            
            _group.addEventListener( NetStatusEvent.NET_STATUS, onNetStatus );
//            trace( "joining group " + name );
            
        }
        
        public function leave():void
        {
            _log( "Node.leave()" );
            
            if( !_joined )
            {
                var message:String = format( NetworkStrings.groupNotJoined, {name:name} );
//                trace( message );
                return;
            }
            
            _group.close();
            _group.removeEventListener( NetStatusEvent.NET_STATUS, onNetStatus );
            _group = null;
        }
        
        public function sendToAll( command:NetworkCommand ):void
        {
            
        }
        
        public function sendTo( address:String, command:NetworkCommand ):void
        {
            
        }
        
        /* note:
           Sends a message to all members of a group.
        */
        public function post( command:NetworkCommand ):String
        {
            if( !_specifier.postingEnabled )
            {
                _log( "## ERROR : posting is not enabled ##" );
                return null;
            }
            
            /* note:
               return the messageID of the message if posted, or null on error.
               The messageID is the hexadecmial of the SHA256 of the raw bytes of the serialization of the message.
            */
            var messageID:String;
            
            if( _network.config.wrapCommandIntoPacket )
            {
                var packet:Packet = Network.serialize( command, _network.config.compressPacket );
                messageID = _group.post( packet );
            }
            else
            {
                messageID = _group.post( command );
            }
            
            if( messageID )
            {
                //message posted
                return messageID;
            }
            else
            {
                //message not posted
                _log( "## ERROR : message not posted ##" );
                return null;
            }
        }
        
        /* note:
           Sends a message to all neighbors.
        */
        public function sendToAllNeighbors( command:NetworkCommand ):String
        {
            var result:String;
            
            if( _network.config.wrapCommandIntoPacket )
            {
                var packet:Packet = Network.serialize( command, _network.config.compressPacket );
                result = _group.sendToAllNeighbors( packet );
            }
            else
            {
                result = _group.sendToAllNeighbors( command );
            }
            
            return result;
        }
        
        /* note:
           Sends a message to the neighbor (or local node) nearest
           to the specified group address.
        */
        public function sendToNearest( command:NetworkCommand, groupAddress:String ):String
        {
            var result:String;
            
            if( _network.config.wrapCommandIntoPacket )
            {
                var packet:Packet = Network.serialize( command, _network.config.compressPacket );
                result = _group.sendToNearest( packet, groupAddress );
            }
            else
            {
                result = _group.sendToNearest( command, groupAddress );
            }
            
            return result;
        }
        
        /* note:
           Sends a message to the neighbor specified by the sendMode parameter.
        */
        public function sendToNeighbor( command:NetworkCommand, sendMode:String ):String
        {
            var result:String;
            
            if( _network.config.wrapCommandIntoPacket )
            {
                var packet:Packet = Network.serialize( command, _network.config.compressPacket );
                result = _group.sendToNeighbor( packet, sendMode );
            }
            else
            {
                result = _group.sendToNeighbor( command, sendMode );
            }
            
            return result;
        }
        
        public function addLocalClient():void { _log( "Node.addLocalClient()" ); _addLocalClient(); }
        public function removeLocalClient():void { _log( "Node.removeLocalClient()" ); _removeLocalClient(); }
        
    }
}