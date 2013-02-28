package library.circulate
{
    public class NetworkType
    {
        public static const local:NetworkType    = new NetworkType( 0x00, "local" );
        public static const internet:NetworkType = new NetworkType( 0x01, "internet" );
        public static const test:NetworkType     = new NetworkType( 0xff, "test" );
        
        private var _value:uint;
        private var _name:String;
        
        public function NetworkType( value:uint, name:String )
        {
            _value = value;
            _name  = name;
        }
        
        public function toString():String { return _name; }
        public function valueOf():int { return _value; }
    }
}