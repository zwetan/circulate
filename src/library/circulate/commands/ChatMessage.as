package library.circulate.commands
{
    import flash.net.registerClassAlias;
    
    import library.circulate.NetworkCommand;
    
    registerClassAlias( "library.circulate.commands.ChatMessage", ChatMessage );
    
    public class ChatMessage implements NetworkCommand
    {
    
        public var message:String;
        public var nodename:String;
        
        public function ChatMessage( message:String = "", nodename:String = "" )
        {
            this.message  = message;
            this.nodename = nodename;
        }
    }
}