package library.circulate.events
{
    import flash.events.Event;
    
    public class NetworkEvent extends Event
    {
        public static const CONNECTED:String    = "network_connected";
        public static const DISCONNECTED:String = "network_disconnected";
        
        public function NetworkEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
        {
            super( type, bubbles, cancelable );
        }
        
        override public function clone():Event
        {
            return new NetworkEvent( type, bubbles, cancelable );
        }
    }
}