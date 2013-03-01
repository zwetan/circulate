package library.circulate.commands
{
    import flash.net.registerClassAlias;
    
    import library.circulate.CommandType;
    import library.circulate.NetworkCommand;
    
    registerClassAlias( "library.circulate.commands.JoinNode", JoinNode );
    
    public class JoinNode implements NetworkCommand
    {
        private var _type:CommandType = CommandType.joinNode;
        
        public var username:String;
        public var peerID:String;
        
        public function JoinNode( username:String = "", peerID:String = "" )
        {
            this.username = username;
            this.peerID   = peerID;
        }
        
        public function get name():String { return _type.toString(); }
        public function get type():CommandType { return _type; }
    }
}