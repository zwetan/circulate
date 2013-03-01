package library.circulate.commands
{
    import flash.net.registerClassAlias;
    
    import library.circulate.CommandType;
    import library.circulate.NetworkCommand;
    
    registerClassAlias( "library.circulate.commands.ChatMessage", ChatMessage );
    
    public class ChatMessage implements NetworkCommand
    {
        private var _type:CommandType = CommandType.chatMessage;
        
        public var message:String;
        public var nodename:String;
        
        public function ChatMessage( message:String = "", nodename:String = "" )
        {
            this.message  = message;
            this.nodename = nodename;
        }
        
        public function get name():String { return _type.toString(); }
        public function get type():CommandType { return _type; }
    }
}