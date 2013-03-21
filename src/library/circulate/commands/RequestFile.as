package library.circulate.commands
{
    import core.reflect.getClassName;
    
    import library.circulate.NetworkCommand;
    import library.circulate.NetworkNode;
    import library.circulate.NetworkSystem;
    
    /* note:
       ask for a file to be shared with you
    */
    public class RequestFile implements NetworkCommand
    {
        private var _destination:String = "";
        
        public var filename:String;
        
        public function RequestFile( filename:String = "" )
        {
            this.filename = filename;
        }
        
        public function get name():String { return getClassName( this ); }
        
        public function get destination():String { return _destination; }
        public function set destination( value:String ):void { _destination = value; }
        
        public function get isRouted():Boolean
        {
            if( destination != "" ) { return true; }
            return false;
        }
        
        public function execute( network:NetworkSystem, node:NetworkNode ):void
        {
            var _log:Function = network.writer;
                _log( this.toString() );
        }
        
        public function toString():String
        {
            var lines:Array = [];
                lines.push( "command [" + name + "]" );
                lines.push( "  |_ destination: " + destination );
                lines.push( "  |_ isRouted: " + isRouted );
                lines.push( "  |_ filename: " + filename );
        }
    }
}