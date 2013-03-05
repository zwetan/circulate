package
{
    import core.reflect.getClassName;
    
    import flash.display.DisplayObject;
    import flash.net.registerClassAlias;
    
    import library.circulate.Network;
    import library.circulate.NetworkCommand;
    import library.circulate.NetworkNode;
    
    /* Test class that illustrates how you can create your own
       custom network commands
       
       here with TestCustomCommand
       we want to create a NetworkCommand that pass
       the x/y coordinates of a graphic object
       
       1. implements NetworkCommand
       2. use registerClassAlias() in the declaration of the class;
       3. by convention use reflection to return the name of the command
          eg. public function get name():String { return getClassName( this ); }
       4. execute() run when this command is received by your client
       5. declare all your properties public (for ex: x and y here)
          and in the ctor provide default parameters
          (you can also implements IExternalizable)
       
       Things to know:
       - you can not pass a display object reference
    */
    registerClassAlias( "TestCustomCommand", TestCustomCommand );
    
    public class TestCustomCommand implements NetworkCommand
    {
        //to hold our ref but we don't serialize/deserialize it
        static public var reference:DisplayObject;
        
        public var x:Number;
        public var y:Number;
        
        public function TestCustomCommand( x:Number = 0, y:Number = 0 )
        {
            this.x = x;
            this.y = y;
        }
        
        public function get name():String { return getClassName( this ); }
        
        public function execute( network:Network, node:NetworkNode ):void
        {
            var _log:Function = network.writer;
                _log( "command [" + name + "]" );
                _log( "  |_ x: " + x );
                _log( "  |_ y: " + y );
            
            if( reference )
            {
                reference.x = x;
                reference.y = y;
                _log( "moved object to x=" + x + ", y=" + y );
            }
        }
    }
}