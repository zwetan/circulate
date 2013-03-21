package library.circulate.commands
{
    import core.reflect.getClassName;
    
    import flash.net.registerClassAlias;
    
    import library.circulate.NetworkClient;
    import library.circulate.NetworkCommand;
    import library.circulate.NetworkNode;
    import library.circulate.NetworkSystem;
    import library.circulate.events.ClientEvent;
    import library.circulate.networks.Network;
    
    registerClassAlias( "library.circulate.commands.KeepAlive", KeepAlive );
    
    /* note:
       to senda beacon of your client information on the network
       eg. "hey I'm here, I'm still alive"
    */
    public class KeepAlive implements NetworkCommand
    {
        private var _destination:String = "";
        
        public var username:String;
        public var peerID:String;
        public var address:String;
        public var elected:Boolean;
        public var arrived:Date;
        public var idle:Date;
        
        public var timestamp:uint;
        
        public function KeepAlive( username:String = "",
                                   peerID:String = "",
                                   address:String = "",
                                   elected:Boolean = false,
                                   arrived:Date = null,
                                   idle:Date = null,
                                   timestamp:uint = 0 )
        {
            this.username  = username;
            this.peerID    = peerID;
            this.address   = address;
            this.elected   = elected;
            this.arrived   = arrived;
            this.idle      = idle;
            this.timestamp = timestamp;
        }
        
        public function get name():String { return getClassName( this ); }
        
        public function get destination():String { return _destination; }
        public function set destination( value:String ):void { _destination = value; }
        
        public function get isRouted():Boolean
        {
            if( destination != "" )
            {
                return true;
            }
            
            return false;
        }
        
        public function execute(network:NetworkSystem, node:NetworkNode):void
        {
            var _log:Function = network.writer;
                _log( "command [" + name + "]" );
                _log( "  |_ username: " + username );
//                _log( "  |_ peerID: " + peerID );
//                _log( "  |_ address: " + address );
//                _log( "  |_ elected: " + elected );
//                _log( "  |_ arrived: " + arrived );
//                _log( "  |_ idle: " + idle );
//                _log( "  |_ timestamp: " + timestamp );
            
            var client:NetworkClient = node.findClientByPeerID( peerID );
            var date:Date = new Date( timestamp ); //when the command was sent
            
            if( client )
            {
                if( client.username == "" )
                {
                    client.username = username;
                }
                
                if( arrived )
                {
                    client.arrivedTime = arrived;
                }
                
                if( idle )
                {
                    client.idleTime = idle;
                }
                
                client.elected = elected;
            }
            
                var clientevent:ClientEvent = new ClientEvent( ClientEvent.UPDATED, client );
                node.dispatchEvent( clientevent );
        }
        
        public function toString():String { return ""; }
    }
}