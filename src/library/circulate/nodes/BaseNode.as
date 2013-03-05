package library.circulate.nodes
{
    import core.strings.format;
    
    import flash.events.NetStatusEvent;
    import flash.net.GroupSpecifier;
    import flash.net.NetGroup;
    import flash.utils.Dictionary;
    
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
        protected var _type:NodeType  = null;
        protected var _name:String    = "";
        protected var _joined:Boolean = false;
        
        protected var _network:Network;
        protected var _group:NetGroup;
        protected var _specifier:GroupSpecifier;
        
        private var _clients:Vector.<NetworkClient>;
        private var _sent:Dictionary;
        private var _last:String;
        
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
            _sent      = new Dictionary();
            _last      = "";
        }
        
        //--- events ---
        
        private function onNetStatus( event:NetStatusEvent ):void
        {
            var code:String   = event.info.code;
            var reason:String = "";
            
            //trace( dump( event, true ) );
            
            _log( _type.toString() + " [" + name + "]"  + " netstatus code: " + event.info.code );
            
            switch( code )
            {
                
                /* ---- NetGroup ---- */
                
//                /* The NetGroup is successfully constructed and authorized to function.
//                   The info.group property indicates which NetGroup has succeeded.
//                */
//                case "NetGroup.Connect.Success": // event.info.group
//                onNodeConnect( event.info.group as NetGroup );
//                break;
//                
//                /* The NetGroup connection attempt failed.
//                   The info.group property indicates which NetGroup failed.
//                */
//                case "NetGroup.Connect.Failed": // event.info.group
//                
//                /* The NetGroup is not authorized to function.
//                   The info.group property indicates which NetGroup was denied.
//                */
//                case "NetGroup.Connect.Rejected": // event.info.group
//                reason = code.split( "." ).pop();
//                onNodeDisconnect( event.info.group as NetGroup, reason.toLowerCase() );
//                break;
                
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
                break;
                
            }
            
        }
        
        
        //--- netstatus actions ---
        
        private function onNodeConnect( netgroup:NetGroup ):void
        {
            _log( "node.onNodeConnect()" );
//			addNeighbour(netGroup, netConnection.nearID, true);
//			dispatchEvent(new GroupEvent(GroupEvent.GROUP_CONNECTED, netGroup));
//			// adds the local client to the list of peers in the NetGroup
            
            _joined = true;
            _addLocalClient(); //we add the local client to the list of clients
        }
        
        private function onNodeDisconnect( netgroup:NetGroup, message:String = "" ):void
        {
            _log( "node.onNodeDisconnect()" );
            
            _removeLocalClient();
            _joined = false;
        }
        
        private function onNeighborConnect( peerID:String, address:String ):void
        {
            _log( "node.onNeighborConnect( " + peerID + " )" );
            _addNeighbour( peerID );
            
            var now:Date = new Date();
            var timestamp:uint = now.valueOf();
            var client:NetworkClient = _network.client;
            //var cmd:NetworkCommand = new ConnectNetwork( client.username, client.peerID, timestamp );
            var cmd:NetworkCommand = new JoinNode( client.username, client.peerID, timestamp );
            
            sendToAll( cmd );
            
            _log( "total clients = " + _clients.length );
            _log( "estimated = " + _group.estimatedMemberCount );
        }
        
        private function onNeighborDisconnect( peerID:String, address:String ):void
        {
            _log( "node.onNeighborDisconnect()" );
            var client:NetworkClient = _findClientByPeerID( peerID );
            var index:uint = _findClientIndex( client );
            
            _removeClient( index );
            
            _log( "total clients = " + _clients.length );
            _log( "estimated = " + _group.estimatedMemberCount );
        }
        
        private function onPostingNotify( id:String, message:Object ):void
        {
            _log( "received packet via POST" );
            _log( "id = " + id );
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
                
                /* note:
                   the workaround here is to send back an empty message
                   and after that everything works well
                */
                var empty:NetworkCommand = new ChatMessage( "", "", "", id );
                sendToAll( empty );
            }
            
            
//            var packet:Packet = message as Packet;
//            var cmd:NetworkCommand;
//            
//            if( packet )
//            {
//                cmd = Network.deserialize( packet, _network.config.compressPacket );
//            }
//            else
//            {
//                _log( "packet is null" );
//                return;
//            }
//            
//            trace( "cmd = " + cmd );
//            if( cmd )
//            {
//                //_interpretCommands( cmd );
//                //_network.interpret( cmd, this );
//                cmd.execute( _network, this );
//            }
//            else
//            {
//                _log( "cmd is null" );
//                _inspectPacket( packet );
//                
////                if( packet && packet.data )
////                {
////                    //deserializing packet manually
////                    packet.data.position = 0;
////                    packet.data.uncompress();
////                    packet.data.position = 0;
////                    
////                    var command:* = packet.data.readObject();
////                    trace( "command = " + command );
////                    
////                    if( command )
////                    {
////                        cmd = command as NetworkCommand;
////                        trace( "cmd2 = " + cmd );
////                    }
////                }
//                
//            }
            
        }
        
        private function onSendToNotify( address:String, message:Object, isLocal:Boolean = false ):void
        {
            
        }
        
        
        //--- private ---
        
        private function _log( message:String ):void
        {
            var log:Function = _network.writer;
            log( message );
        }
        
        private function _inspectPacket( packet:Packet ):void
        {
            _log( "packet = " + packet );
            if( packet )
            {
            _log( "  |_ id: " + packet.id );
            _log( "  |_ data: " + packet.data.length + "bytes" );
            }
        }
        
        private function _addClient( client:NetworkClient ):void
        {
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
            _clients.splice( index, 1 );
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
        
        private function _addLocalClient():void
        {
            _addClient( _network.client );
            _joined = true;
        }
        
        private function _removeLocalClient():void
        {
            var client:NetworkClient = _network.client;
            var index:uint = _findClientIndex( client );
            _removeClient( index );
            _joined = false;
        }
        
        private function _addNeighbour( peerID:String ):void
        {
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
        
        public function get clients():Vector.<NetworkClient> { return _clients; }
        public function get sent():Dictionary { return _sent; }
        
        public function findClientByPeerID( peerID:String ):NetworkClient
        {
            return _findClientByPeerID( peerID );
        }
        
        public function join( password:String = "" ):void
        {
            if( _joined || _group )
            {
                var message:String = format( NetworkStrings.groupAlreadyJoined, {name:name} );
                trace( message );
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
            trace( "joining group " + name );
        }
        
        public function leave():void
        {
            if( !_joined )
            {
                var message:String = format( NetworkStrings.groupNotJoined, {name:name} );
                trace( message );
                return;
            }
            
            _group.close();
            _group.removeEventListener( NetStatusEvent.NET_STATUS, onNetStatus );
            _group = null;
        }
        
        public function sendToAll( command:NetworkCommand ):void
        {
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
                //message posted and we save it
                _sent[ messageID ] = command;
                _last = messageID;
            }
            else
            {
                //message not posted
                _log( "## ERROR : message not posted ##" );
            }
            
        }
        
        public function sendTo():void
        {
            /* Sends a message to all neighbors.
               Returns NetGroupSendResult.SENT if at least one neighbor was selected.
            */
            //_group.sendToAllNeighbors( message:Object):String
            
            /* Sends a message to the neighbor (or local node) nearest to the specified group address.
               Considers neighbors from the entire ring.
               Returns NetGroupSendResult.SENT if the message was successfully sent toward its destination.
            */
            //_group.sendToNearest( message:Object, groupAddress:String ):String
            
            /* Sends a message to the neighbor specified by the sendMode parameter
               Returns NetGroupSendResult.SENT if the message was successfully sent to the requested destination.
            */
            //_group.sendToNeighbor( message:Object, sendMode:String ):String
            
        }
        
        public function addLocalClient():void { _addLocalClient(); }
        public function removeLocalClient():void { _removeLocalClient(); }
        
    }
}