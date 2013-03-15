package library.circulate.nodes
{
    import core.strings.format;
    import core.strings.startsWith;
    
    import flash.events.EventDispatcher;
    import flash.events.NetStatusEvent;
    import flash.net.GroupSpecifier;
    import flash.net.NetGroup;
    import flash.net.NetGroupReceiveMode;
    import flash.net.NetGroupSendResult;
    import flash.net.NetStream;
    
    import library.circulate.RingTopology;
    import library.circulate.NetworkClient;
    import library.circulate.NetworkCommand;
    import library.circulate.NetworkNode;
    import library.circulate.NetworkStrings;
    import library.circulate.NetworkSystem;
    import library.circulate.NodeType;
    import library.circulate.data.Packet;
    import library.circulate.clients.Client;
    import library.circulate.commands.KeepAlive;
    import library.circulate.events.ClientEvent;
    import library.circulate.events.NeighborEvent;
    import library.circulate.networks.Network;
    
    /**
    * A Node is responsible for creating, connecting and managing Clients.
    * Can be associated with only one NetGroup or NetStream.
    * 
    * This is the Base class for all NetworkNode.
    */
    public class Node extends EventDispatcher implements NetworkNode
    {
        protected var FULLMESH:uint      = 14;
        
        protected var _type:NodeType     = null;
        protected var _name:String       = "";
        protected var _joined:Boolean;
        protected var _isElected:Boolean;
        protected var _groupAddress:String;
        
        protected var _network:NetworkSystem;
        protected var _group:NetGroup;
        protected var _specifier:GroupSpecifier;
        
        protected var _clients:Vector.<NetworkClient>;
        
        public function Node( network:NetworkSystem, name:String = "", specifier:GroupSpecifier = null )
        {
            if( !specifier )
            {
                specifier = Network.getDefaultGroupSpecifier( name, network.config.IPMulticastAddress );
            }
            
            _network   = network;
            _name      = name;
            _specifier = specifier;
            
            _reset();
            
            _log( "Node.ctor( \"" + name + "\" )" );
        }
        
        
        //--- events ---
        
        private function onNetStatus( event:NetStatusEvent ):void
        {
            var code:String   = event.info.code;
            var reason:String = "";
            
            _log( "Node.onNetStatus( " + event.info.code + " )" );
            
            switch( code )
            {
                
                /* ---- NetGroup ---- */
                
                /* Sent when a neighbor connects to this node.
                   The info.neighbor:String property is the group address of the neighbor.
                   The info.peerID:String property is the peer ID of the neighbor.
                */
                case "NetGroup.Neighbor.Connect": // event.info.neighbor, event.info.peerID
                doNeighborConnect( event.info.peerID, event.info.neighbor );
                break;
                
                /* Sent when a neighbor disconnects from this node.
                   The info.neighbor:String property is the group address of the neighbor.
                   The info.peerID:String property is the peer ID of the neighbor.
                */
                case "NetGroup.Neighbor.Disconnect": // event.info.neighbor, event.info.peerID
                doNeighborDisconnect( event.info.peerID, event.info.neighbor );
                break;
                
                /* Sent when a portion of the group address space for
                   which this node is responsible changes.
                */
                case "NetGroup.LocalCoverage.Notify":
                doLocalCoverageNotify();
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
                _log( "NetGroup.SendTo.Notify( " + event.info.from + ", " + event.info.message + ", " + event.info.fromLocal + " )" );
                doSendToNotify( event.info.from, event.info.message, event.info.fromLocal );
                break;
                
                /* Sent when a new Group Posting is received.
                   The info.message:Object property is the message.
                   The info.messageID:String property is this message's messageID.
                */
                case "NetGroup.Posting.Notify": // event.info.message, event.info.messageID
                doPostingNotify( event.info.messageID, event.info.message );
                break;
                
                
                /* ---- NetGroup.Replication ---- */
                
                /* Sent when a fetch request for an object
                   (previously announced with NetGroup.Replication.Fetch.SendNotify)
                   fails or is denied.
                   A new attempt for the object will be made if it is still wanted.
                   The info.index:Number property is the index of the object that had been requested.
                */
                case "NetGroup.Replication.Fetch.Failed": // event.info.index
                doReplicationFetchFailed( event.info.index );
                break;
                
                /* Sent when a fetch request was satisfied by a neighbor.
                   The info.index:Number property is the object index of this result.
                   The info.object:Object property is the value of this object.
                   This index will automatically be removed from the Want set.
                   If the object is invalid, this index can be re-added to the Want set with NetGroup.addWantObjects().
                */
                case "NetGroup.Replication.Fetch.Result": // event.info.index, event.info.object
                doReplicationFetchResult( event.info.index, event.info.object );
                break;
                
                /* Sent when the Object Replication system is about to send a request for an object to a neighbor.
                   The info.index:Number property is the index of the object that is being requested.
                */
                case "NetGroup.Replication.Fetch.SendNotify": // event.info.index
                doReplicationFetchSendNotify( event.info.index );
                break;
                
                /* Sent when a neighbor has requested an object that this node has announced with NetGroup.addHaveObjects().
                   This request must eventually be answered with either NetGroup.writeRequestedObject()
                   or NetGroup.denyRequestedObject().
                   Note that the answer may be asynchronous.
                   The info.index:Number property is the index of the object that has been requested.
                   The info.requestID:int property is the ID of this request,
                   to be used by NetGroup.writeRequestedObject() or NetGroup.denyRequestedObject().
                */
                case "NetGroup.Replication.Request": // event.info.index, event.info.requestID
                doReplicationRequest( event.info.index, event.info.requestID );
                break;
            }
            
        }
        
        
        //--- netstatus actions ---
        
        private function doNeighborConnect( peerID:String, address:String ):void
        {
            _log( "Node.onNeighborConnect( " + peerID + ", " + address + " )" );
            
            setReceiveMode();
            
            _addNeighbour( peerID );
            
            //onNeighborConnectAction( peerID, address );
            
            var client:NetworkClient = new Client();
                client.peerID  = peerID;
                client.address = address;
            
            var neighborevent:NeighborEvent = new NeighborEvent( NeighborEvent.CONNECT, client );
            dispatchEvent( neighborevent );
        }
        
        private function doNeighborDisconnect( peerID:String, address:String ):void
        {
            _log( "Node.onNeighborDisconnect( " + peerID + ", " + address + " )" );
            
            var client:NetworkClient = _findClientByPeerID( peerID );
            var index:uint = _findClientIndex( client );
            //var username:String = client.username;
            
            _removeClient( index );
            //onNeighborDisconnectAction( peerID, address, username );
            
            var neighborevent:NeighborEvent = new NeighborEvent( NeighborEvent.DISCONNECT, client );
            dispatchEvent( neighborevent );
        }
        
        private function doLocalCoverageNotify():void
        {
            _log( "Node.onLocalCoverageNotify()" );
            
            _runElection();
        }
        
        /* note:
           
           id      - event.info.messageID - is the message ID ( the hexadecmial of the SHA256 of the raw bytes of the serialization of the message.)
           message - event.info.message   - is the message
        */
        private function doPostingNotify( id:String, message:Object ):void
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
        
        /* note:
           
           address - event.info.from      - is the groupAddress from which the message was received.
           message - event.info.message   - is the message.
           isLocal - event.info.fromLocal - is TRUE if the message was sent by this node
           
           To implement recursive routing, the message must be resent with NetGroup.sendToNearest()
           if info.fromLocal is FALSE.
        */
        private function doSendToNotify( address:String, message:Object, isLocal:Boolean = false ):void
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
                _log( "command is not null" );
                _log( "destination = " + cmd.destination );
                
                if( cmd.isRouted && (cmd.destination == groupAddress) )
                {
                    _log( "command arrived to destination" );
                    
                    if( isLocal && _network.config.loopback )
                    {
                        _log( ">>>> A" );
                        _log( "command roundtriped back to you" );
                        cmd.execute( _network, this );
                    }
                    else if( _network.config.loopback )
                    {
                        _log( ">>>> B" );
                        _log( "command is not from self but address found" );
                        
                        cmd.execute( _network, this );
                        //sendToNearest( cmd, cmd.destination );
                    }
                    
                }
                else if( !isLocal )
                {
                    _log( ">>>> C" );
                    _log( "command is not from self" );
                    cmd.execute( _network, this );
                    sendToNearest( cmd, cmd.destination );
                }
                
            }
            else
            {
                _log( "cmd is null" );
            }
            
        }
        
        protected function doReplicationFetchFailed( index:Number ):void
        {
            _log( "Node.doReplicationFetchFailed( " + index + " )" );
        }
        
        protected function doReplicationFetchResult( index:Number, data:Object ):void
        {
            _log( "Node.doReplicationFetchResult( " + index + ", " + data + " )" );
        }
        
        protected function doReplicationFetchSendNotify( index:Number ):void
        {
            _log( "Node.doReplicationFetchSendNotify( " + index + " )" );
        }
        
        protected function doReplicationRequest( index:Number, requestID:int ):void
        {
            _log( "Node.doReplicationRequest( " + index + ", " + requestID + " )" );
        }
        
        //--- private ---
        
        private function _log( message:String ):void
        {
            var log:Function = _network.writer;
            
            if( startsWith( message, ">" ) )
            {
                log( message );
            }

//            log( message );
        }
        
        private function _reset():void
        {
            _log( "Node._reset()" );
            
            _joined    = false;
            _isElected = false;
            _clients   = new Vector.<NetworkClient>();
        }
        
        private function _destroy():void
        {
            _clients = null;
        }
        
        private function _runElection():void
        {
			var rangeFrom:String = _group.localCoverageFrom;
			var rangeTo:String   = _group.localCoverageTo;
			var election:Boolean = RingTopology.triangulate( rangeFrom, rangeTo );
			
            if( election != _isElected )
            {
                _log( "Election change: " + (election ? "elected" : "not elected") );
                
                var client:NetworkClient = _network.client;
                    client.elected = election;
                
                var now:Date = new Date();
                _network.client.idleTime = now;
                var cmd:KeepAlive = new KeepAlive();
                    cmd.username  = client.username;
                    cmd.peerID    = client.peerID;
                    cmd.address   = groupAddress;
                    cmd.elected   = client.elected;
                    cmd.arrived   = client.arrivedTime;
                    cmd.idle      = client.idleTime;
                    cmd.timestamp = now.valueOf();
                    
                
                var clientevent:ClientEvent = new ClientEvent( ClientEvent.UPDATED, client );
                dispatchEvent( clientevent );
                sendToAll( cmd );
                //post( cmd );
            }
            
            _isElected = election;
            _log( "isElected = " + _isElected );
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
            
            var clientevent:ClientEvent = new ClientEvent( ClientEvent.ADDED, client );
            dispatchEvent( clientevent );
        }
        
        private function _removeClient( index:uint ):void
        {
            _log( "Node._removeClient( " + index + " )" );
            
            var client:NetworkClient = _clients[ index ];
            
            _clients.splice( index, 1 );
            //onRemoveClient( client );
            
            var clientevent:ClientEvent = new ClientEvent( ClientEvent.REMOVED, client );
            dispatchEvent( clientevent );
        }
        
        private function _removeAllClient():void
        {
            _log( "Node._removeAllClient()" );
            
            var i:uint;
            var c:NetworkClient;
            
            for( i=0; i<_clients.length; i++ )
            {
                _removeClient( i );
            }
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
        
        private function _findClientByName( username:String ):NetworkClient
        {
            _log( "Node._findClientByName( " + username + " )" );
            
            var i:uint;
            var client:NetworkClient;
            
            for( i=0; i<_clients.length; i++ )
            {
                client = _clients[i];
                
                if( client.username == username )
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
            
            var local:NetworkClient = _network.client;
            trace( "local = " + local );
            _addClient( local );
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
        
        //--- protected ---
        
        /* Those methods are meant to be overrided to customize
           the behaviour of the NetworkNode
        */
        
        protected function setReceiveMode():void
        {
            _log( "Node.setReceiveMode()" );
            _group.receiveMode = NetGroupReceiveMode.EXACT;
        }
        
        
        //DELETE
        protected function onNeighborConnectAction( peerID:String, address:String ):void
        {
            _log( "Node.onNeighborConnectAction( " + peerID + ", " + address + " )" );
        }
        
        //DELETE
        protected function onNeighborDisconnectAction( peerID:String, address:String, username:String ):void
        {
            _log( "Node.onNeighborDisconnectAction( " + peerID + ", " + address + ", " + username + " )" );
        }
        
        /* note:
           Sends a message to all members of a group.
           
           All messages must be unique.
           A message that is identical to one posted earlier might not be propagated.
           Use a sequence number to make messages unique. (UniquePacket take care of that

           Message delivery is not ordered.
           Message delivery is not guaranteed.
        */
        protected function post( command:NetworkCommand ):String
        {
            _log( "Node.post( " + command + " )" );
            
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
            
            return messageID;
        }
        
        /* note:
           Sends a message to all neighbors.
        */
        protected function sendToAllNeighbors( command:NetworkCommand ):String
        {
            _log( "Node.sendToAllNeighbors( " + command + " )" );
            
            if( !_specifier.routingEnabled )
            {
                _log( "## ERROR : routing is not enabled ##" );
                return NetGroupSendResult.ERROR;
            }
            
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
        protected function sendToNearest( command:NetworkCommand, groupAddress:String ):String
        {
            _log( "Node.sendToNearest( " + command + ", " + groupAddress + " )" );
            
            if( !_specifier.routingEnabled )
            {
                _log( "## ERROR : routing is not enabled ##" );
                return NetGroupSendResult.ERROR;
            }
            
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
        protected function sendToNeighbor( command:NetworkCommand, sendMode:String ):String
        {
            _log( "Node.sendToNeighbor( " + command + ", " + sendMode + " )" );
            
            if( !_specifier.routingEnabled )
            {
                _log( "## ERROR : routing is not enabled ##" );
                return NetGroupSendResult.ERROR;
            }
            
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
        
        protected function afterMessageRouted( result:String ):void
        {
            switch( result )
            {
                case NetGroupSendResult.SENT:
                _log( "message successfully routed" );
                break;
                
                case NetGroupSendResult.NO_ROUTE:
                _log( "## WARNING : message could notfind a route ##" );
                break;
                
                case NetGroupSendResult.ERROR:
                _log( "## ERROR : message not routed ##" );
                break;
            }
        }
        
        protected function afterMessagePosted( messageID:String ):void
        {
           if( messageID )
            {
                _log( "message " + messageID + "  successfully routed" );
            }
            else
            {
                _log( "## ERROR : message not posted ##" );
            }
        }
        
        
        //--- public ---
        
        /* note:
           what we can consider the public API
           or the implementation of NetworkNode
        */
        
        public function get type():NodeType { return _type; }
        public function get name():String { return _name; }
        public function get specificier():GroupSpecifier { return _specifier; }
        public function get group():NetGroup { return _group; }
        public function get stream():NetStream { return null; }
        public function get joined():Boolean { return _joined; }
        public function get isElected():Boolean { return _isElected; }
        
        public function get isFullMesh():Boolean
        {
            if( _group )
            {
                return estimatedMemberCount <= FULLMESH;
            }
            
            return false;
        }
        
        public function get groupAddress():String
        {
            if( _group && !_groupAddress )
            {
                _groupAddress = _group.convertPeerIDToGroupAddress( _network.client.peerID );
            }
            
            return _groupAddress;
        }
        
        public function get streamAddress():String { return ""; }
        
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
        
        public function addLocalClient():void { _log( "Node.addLocalClient()" ); _addLocalClient(); }
        
        public function removeLocalClient():void { _log( "Node.removeLocalClient()" ); _removeLocalClient(); }
        
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
            
            if( _group )
            {
                _group.close();
                _group.removeEventListener( NetStatusEvent.NET_STATUS, onNetStatus );
                _group = null;
            }
            
            _removeAllClient();
            _reset();
        }
        
        public function sendToAll( command:NetworkCommand ):void
        {
            if( !_specifier.postingEnabled && !_specifier.routingEnabled )
            {
                trace( "this group can not send message to all" );
                return;
            }
            
            if( isFullMesh )
            {
                var result:String = sendToAllNeighbors( command );
                //var result:String = sendToNearest( command, _groupAddress );
                //var result:String = sendToNeighbor( command, NetGroupSendMode.NEXT_DECREASING );
                afterMessageRouted( result );
            }
            else
            {
                var messageID:String = post( command );
                afterMessagePosted( messageID );
            }
            
            if( _network.config.loopback )
            {
                command.execute( _network, this );
            }
            
        }
        
        public function sendTo( peerID:String, command:NetworkCommand ):void
        {
            var groupAddress:String = _group.convertPeerIDToGroupAddress( peerID );
            sendToNearest( command, groupAddress );
        }
        
        public function sendToUser( name:String, command:NetworkCommand ):void
        {
            var client:NetworkClient = _findClientByName( name );
            
            if( client )
            {
                sendTo( client.peerID, command );
            }
            else
            {
                trace( "username \"" + name + "\" did not resolve to a known client" );
            }
        }
        
        public function sendToGroup( address:String, command:NetworkCommand ):void
        {
            sendToNearest( command, address );
        }
        
        /**
        * Completely destroy the current node
        * can not be reversed
        * this is meant to clean up memory
        */
        public function destroy():void { _destroy(); }
        
    }
}