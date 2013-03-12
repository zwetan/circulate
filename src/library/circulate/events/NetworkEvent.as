package library.circulate.events
{
    import flash.events.Event;
    
    public class NetworkEvent extends Event
    {
        /** dispatched when connected to a NetworkSystem */
        public static const CONNECTED:String    = "network_connected";
        
        /** dispatched when disconnected from a NetworkSystem */
        public static const DISCONNECTED:String = "network_disconnected";
        
        /** dispatched when the CommandCenter is ready */
        public static const COMMANDCENTER_READY:String = "network_commandcenter_ready";
        
        public function NetworkEvent( type:String, 
                                      bubbles:Boolean = false, cancelable:Boolean = false )
        {
            super( type, bubbles, cancelable );
        }
        
        public override function clone():Event
        {
            return new NetworkEvent( type, bubbles, cancelable );
        }
        
        public override function toString():String
        {
            return formatToString( "NetworkEvent", "type", "bubbles", "cancelable" );
        }
    }
}