package library.circulate.commands
{
    import core.reflect.getClassName;
    import core.strings.format;
    
    import flash.net.registerClassAlias;
    
    import library.circulate.NetworkClient;
    import library.circulate.NetworkCommand;
    import library.circulate.NetworkNode;
    import library.circulate.NetworkSystem;
    import library.circulate.data.UniquePacket;
    import library.circulate.networks.Network;
    
    registerClassAlias( "library.circulate.commands.ChatMessage", ChatMessage );
    
    public class ChatMessage implements NetworkCommand
    {
        private var _destination:String = "";
        
        public var message:String;
        public var peerID:String;
        public var nodename:String;
        public var id:String;
        
        public function ChatMessage( message:String = "",
                                     peerID:String = "",
                                     nodename:String = "",
                                     id:String = "" )
        {
            this.message     = message;
            this.peerID      = peerID;
            this.nodename    = nodename;
            this.id          = id;
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
//                _log( "  |_ message: " + message );
//                _log( "  |_ peerID: " + peerID );
//                _log( "  |_ nodename: " + nodename );
//                _log( "  |_ id: " + id );
            
//            if( message == "" )
//            {
//                _log( "message is empty, we ignore it" );
//                if( (id != "") && (node.sent[id])  )
//                {
//                    //testing for id allow us to display the message only to the sender
//                    _log( "your last message may have not arrived to destination" );
//                }
//                return;
//            }
            
            var client:NetworkClient;
            
            if( message == "" )
            {
//                if( peerID != "" )
//                {
//                    client = node.findClientByPeerID( peerID );
//                    if( client == network.client )
//                    {
//                        _log( "your last message may have not arrived to destination" );
//                    }
//                }
                
                _log( ">>>>> your last message may have not arrived to destination" );
                return;
            }
            
            client = node.findClientByPeerID( peerID );
            var username:String = "unknown";
            
            if( client && (client.username != "") )
            {
                username = client.username;
            }
            
            if( nodename == "" )
            {
                nodename = node.name;
            }
            
            
            var str:String = ">>>>> [={node}] <{user}> says \"{message}\".";
            var msg:String = format( str, {node:nodename,user:username,message:message} );
            _log( msg );
        }
        
        public function toString():String { return ""; }
    }
}