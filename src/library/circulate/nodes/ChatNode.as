package library.circulate.nodes
{
    import flash.net.GroupSpecifier;
    import flash.net.NetGroupReceiveMode;
    
    import library.circulate.networks.Network;
    import library.circulate.NetworkClient;
    import library.circulate.NetworkCommand;
    import library.circulate.NodeType;
    import library.circulate.commands.JoinNode;
    
    public class ChatNode extends Node
    {
        
        public function ChatNode( network:Network, name:String = "" )
        {
            var specifier:GroupSpecifier = Network.getDefaultGroupSpecifier( name, network.config.IPMulticastAddress );
                specifier.routingEnabled = true;
                specifier.postingEnabled = true;
            
            super( network, name, specifier );
            //super( network, name );
            _type = NodeType.chat;
        }
        
        protected override function setReceiveMode():void
        {
            _group.receiveMode = NetGroupReceiveMode.NEAREST;
        }
        
        protected override function onNeighborConnectAction( peerID:String, address:String ):void
        {
            var now:Date = new Date();
            var timestamp:uint = now.valueOf();
            var client:NetworkClient = _network.client;
            var cmd:NetworkCommand = new JoinNode( client.username, client.peerID, timestamp );
                cmd.destination = address
            
            //sendTo( peerID, cmd );
            sendToGroup( address, cmd );
        }
        
    }
}