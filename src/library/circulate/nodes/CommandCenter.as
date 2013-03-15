package library.circulate.nodes
{
    import flash.net.GroupSpecifier;
    import flash.net.NetGroupReceiveMode;
    import flash.utils.Timer;
    
    import library.circulate.NetworkClient;
    import library.circulate.NetworkCommand;
    import library.circulate.NetworkSystem;
    import library.circulate.NodeType;
    import library.circulate.commands.JoinNode;
    import library.circulate.commands.KeepAlive;
    import library.circulate.commands.LeaveNode;
    import library.circulate.events.ClientEvent;
    import library.circulate.events.NeighborEvent;
    import library.circulate.networks.Network;
    
    public class CommandCenter extends Node
    {
        private var _keepAlive:Timer;
        
        public function CommandCenter( network:NetworkSystem, name:String = "" )
        {
            var specifier:GroupSpecifier = Network.getDefaultGroupSpecifier( name, network.config.IPMulticastAddress );
                specifier.routingEnabled = true;
                specifier.postingEnabled = true;
            
            super( network, name, specifier );
            //super( network, name );
            _type = NodeType.command;
            
            _ctor();
        }
        
        private function _ctor():void
        {
            addEventListener( NeighborEvent.CONNECT, onNeighborConnect );
            addEventListener( NeighborEvent.DISCONNECT, onNeighborDisconnect );
            
            //addEventListener( ClientEvent.UPDATED, onClientUpdate );
        }
        
        private function onNeighborConnect( event:NeighborEvent ):void
        {
            var client:NetworkClient = event.client;
            
            var clientevent:ClientEvent = new ClientEvent( ClientEvent.CONNECTED, client );
            dispatchEvent( clientevent );
            
            var now:Date = new Date();
            var timestamp:uint = now.valueOf();
            
            var local:NetworkClient = _network.client;
            
            var cmd:KeepAlive = new KeepAlive();
                cmd.username  = local.username;
                cmd.peerID    = local.peerID;
                cmd.address   = local.address;
                cmd.arrived   = local.arrivedTime;
                cmd.idle      = local.idleTime;
                cmd.elected   = local.elected;
                cmd.timestamp = timestamp;
            
            //sendToAll( cmd );
            sendTo( client.peerID, cmd );
        }
        
        private function onNeighborDisconnect( event:NeighborEvent ):void
        {
            var client:NetworkClient = event.client;
            
            var clientevent:ClientEvent = new ClientEvent( ClientEvent.REMOVED, client );
            dispatchEvent( clientevent );
        }
        
        private function onClientUpdate( event:ClientEvent ):void
        {
            var client:NetworkClient = event.client;
            
            var clientevent:ClientEvent = new ClientEvent( ClientEvent.UPDATED, client );
            dispatchEvent( clientevent );
        }
        
        protected override function setReceiveMode():void
        {
            _group.receiveMode = NetGroupReceiveMode.NEAREST;
        }
        
    }
}