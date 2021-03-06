package library.circulate.commands
{
    import core.reflect.getClassName;
    
    import flash.net.registerClassAlias;
    
    import library.circulate.NetworkClient;
    import library.circulate.NetworkCommand;
    import library.circulate.NetworkNode;
    import library.circulate.NetworkSystem;
    import library.circulate.networks.Network;
    
    registerClassAlias( "library.circulate.commands.LeaveNode", LeaveNode );
    
    public class LeaveNode implements NetworkCommand
    {
        private var _destination:String = "";
        
        public var username:String;
        public var peerID:String;
        public var timestamp:uint;
        
        public function LeaveNode( username:String = "",
                                   peerID:String = "",
                                   timestamp:uint = 0 )
        {
            this.username  = username;
            this.peerID    = peerID;
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
        
        public function execute( network:NetworkSystem, node:NetworkNode ):void
        {
            var _log:Function = network.writer;
//                _log( "command [" + name + "]" );
//                _log( "  |_ username: " + username );
//                _log( "  |_ peerID: " + peerID );
//                _log( "  |_ timestamp: " + timestamp );
            
            _log( ">>>>> client <" + username +"> left [" + node.name + "]" );
        }
    }
}