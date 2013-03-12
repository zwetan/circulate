package library.circulate.commands
{
    import core.reflect.getClassName;
    
    import flash.net.registerClassAlias;
    
    import library.circulate.networks.Network;
    import library.circulate.NetworkClient;
    import library.circulate.NetworkCommand;
    import library.circulate.NetworkNode;
    
    registerClassAlias( "library.circulate.commands.SystemMessage", SystemMessage );
    
    public class SystemMessage implements NetworkCommand
    {
        public var message:String;
        public var peerID:String;
        
        public function SystemMessage( message:String = "", peerID:String = "" )
        {
            this.message  = message;
            this.peerID   = peerID;
        }
        
        public function get name():String { return getClassName( this ); }
        
        public function execute( network:Network, node:NetworkNode ):void
        {
            var _log:Function = network.writer;
//                _log( "command [" + name + "]" );
//                _log( "  |_ message: " + message );
//                _log( "  |_ peerID: " + peerID );
            
            var client:NetworkClient = node.findClientByPeerID( peerID );
            
            if( client == network.client )
            {
                if( network.config.loopback )
                {
                    _log( "*[system] : " + message );
                }
            }
            else
            {
                _log( "[system] : " + message );
            }
            
        }
    }
}