package library.circulate.commands
{
    import flash.net.registerClassAlias;
    
    import library.circulate.CommandType;
    import library.circulate.NetworkCommand;
    
    registerClassAlias( "library.circulate.commands.ConnectNetwork", ConnectNetwork );
    
    public class ConnectNetwork implements NetworkCommand
    {
        private var _type:CommandType = CommandType.connectNetwork;
        
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
        
        public function get name():String { return _type.toString(); }
        public function get type():CommandType { return _type; }
        
    }
}