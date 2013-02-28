package library.circulate
{
    public class NodeType
    {
        public static const command:NodeType = new NodeType( 0x000, "command" );
        public static const chat:NodeType    = new NodeType( 0x011, "chat" );
        public static const swarm:NodeType   = new NodeType( 0x021, "swarm" );
        public static const onefile:NodeType = new NodeType( 0x022, "onefile" );
        
        private var _value:uint;
        private var _name:String;
        
        public function NodeType( value:uint, name:String )
        {
            _value = value;
            _name  = name;
        }
        
        public function toString():String { return _name; }
        public function valueOf():int { return _value; }
    }
}