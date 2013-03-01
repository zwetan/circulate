package library.circulate
{
    import library.circulate.commands.ChatMessage;
    import library.circulate.commands.JoinNode;

    public class CommandType
    {
        //global - 0x-00
        public static const keepAlive:CommandType         = new CommandType( 0x000, "keepAlive", null );
        
        //network - 0x-10
        public static const connectNetwork:CommandType    = new CommandType( 0x011, "connectNetwork", null );
        public static const disconnectNetwork:CommandType = new CommandType( 0x012, "disconnectNetwork", null );
        
        //node - 0x-20
        public static const joinNode:CommandType          = new CommandType( 0x021, "joinNode", JoinNode );
        public static const leaveNode:CommandType         = new CommandType( 0x022, "leaveNode", null );
        
        //chat - 0x1-0
        public static const chatMessage:CommandType       = new CommandType( 0x101, "chatMessage", ChatMessage );
        
        
        private var _value:uint;
        private var _name:String;
        private var _type:Class;
        
        public function CommandType( value:uint, name:String, type:Class )
        {
            _value = value;
            _name  = name;
            _type  = type;
        }
        
        public function get type():Class { return _type; }
        
        public function isValid():Boolean { return _type != null; }
        
        public function toString():String { return _name; }
        public function valueOf():int { return _value; }
        
    }
}