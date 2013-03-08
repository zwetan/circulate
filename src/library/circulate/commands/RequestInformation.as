package library.circulate.commands
{
    import core.reflect.getClassName;
    
    import flash.net.registerClassAlias;
    
    import library.circulate.Network;
    import library.circulate.NetworkClient;
    import library.circulate.NetworkCommand;
    import library.circulate.NetworkNode;
    
    registerClassAlias( "library.circulate.commands.RequestInformation", RequestInformation );
    
    public class RequestInformation implements NetworkCommand
    {
        public var peerID:String;
        
        public function RequestInformation( peerID:String = "" )
        {
            this.peerID = peerID;
        }
        
        public function get name():String { return getClassName( this ); }
        
        public function execute( network:Network, node:NetworkNode ):void
        {
            var _log:Function = network.writer;
//                _log( "command [" + name + "]" );
//                _log( "  |_ peerID: " + peerID );
            
            var requester:NetworkClient = node.findClientByPeerID( peerID );
            _log( ">>>>> client <" + requester.username +"> request my info" );
            
            //var groupAddress:String = node.group.convertPeerIDToGroupAddress( peerID );
            
            //my info
            var now:Date = new Date();
            var timestamp:uint = now.valueOf();
            var client:NetworkClient = network.client;
            var cmd:NetworkCommand = new JoinNode( client.username, client.peerID, timestamp );
            
            node.sendTo( peerID, cmd );
        }
    }
}