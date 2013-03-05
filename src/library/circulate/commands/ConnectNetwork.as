package library.circulate.commands
{
    import core.reflect.getClassName;
    
    import flash.net.registerClassAlias;
    
    import library.circulate.Network;
    import library.circulate.NetworkClient;
    import library.circulate.NetworkCommand;
    import library.circulate.NetworkNode;
    
    registerClassAlias( "library.circulate.commands.ConnectNetwork", ConnectNetwork );
    
    public class ConnectNetwork implements NetworkCommand
    {
        
        public var username:String;
        public var peerID:String;
        public var timestamp:uint;
        
        public function ConnectNetwork( username:String = "",
                                        peerID:String = "",
                                        timestamp:uint = 0 )
        {
            this.username  = username;
            this.peerID    = peerID;
            this.timestamp = timestamp;
        }
        
        public function get name():String { return getClassName( this ); }
        
        public function execute( network:Network, node:NetworkNode ):void
        {
            var _log:Function = network.writer;
                _log( "command [" + name + "]" );
                _log( "  |_ username: " + username );
                _log( "  |_ peerID: " + peerID );
                _log( "  |_ timestamp: " + timestamp );
            
            var client:NetworkClient = node.findClientByPeerID( peerID );
            var date:Date = new Date( timestamp );
            
            if( client && (client.username == "") )
            {
                client.username = username;
            }
            
            _log( "[system] : <" + username + "> connected to [" + node.name + "] @ " + date.toString()  );
        }
        
    }
}