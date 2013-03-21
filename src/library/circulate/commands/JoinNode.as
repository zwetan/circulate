package library.circulate.commands
{
    import core.reflect.getClassName;
    import core.strings.format;
    
    import flash.net.registerClassAlias;
    
    import library.circulate.NetworkClient;
    import library.circulate.NetworkCommand;
    import library.circulate.NetworkNode;
    import library.circulate.NetworkSystem;
    import library.circulate.networks.Network;
    
    registerClassAlias( "library.circulate.commands.JoinNode", JoinNode );
    
    public class JoinNode implements NetworkCommand
    {
        private var _destination:String = "";
        
        public var username:String;
        public var peerID:String;
        public var timestamp:uint;
        
        public function JoinNode( username:String = "",
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
            
            var client:NetworkClient = node.findClientByPeerID( peerID );
            var date:Date = new Date( timestamp );
            
            if( client && (client.username == "") )
            {
                client.username = username;
            }
            
            _log( ">>>>> found client <" + username +"> in [" + node.name + "]" );
            
//            var str:String = "<{user}> (you) arrived in [{node}] @ {date}";
//            var sysstr:String = "<{user}> joined [{node}] @ {date}";
//            
//            if( network.client != client )
//            {
//                str = sysstr;
//            }
//            
//            var msg:String = format( str, {user:username,node:node.name,date:date.toString()} );
//            var sysmsg:String = format( sysstr, {user:username,node:node.name,date:date.toString()} );
//            _log( msg );
//            
//            var syscmd:NetworkCommand = new SystemMessage( sysmsg, peerID );
//            network.sendCommandToNode( syscmd, network.commandCenter );
            
        }
        
        public function toString():String { return ""; }
    }
}