package library.circulate.events
{
    import flash.events.Event;
    
    import library.circulate.NetworkClient;
    
    /**
    * 
    */
    public class ClientEvent extends Event
    {
        public static const CONNECTED:String = "client_connected";
        public static const ADDED:String     = "client_added";
        public static const REMOVED:String   = "client_removed";
        public static const UPDATED:String   = "client_updated";
        public static const IDLE:String      = "client_idle";
        
        public var client:NetworkClient;
        
        public function ClientEvent( type:String, client:NetworkClient,
                                     bubbles:Boolean = false,
                                     cancelable:Boolean = false )
        {
            super( type, bubbles, cancelable );
            this.client = client;
        }
        
        public override function clone():Event
        {
            return new ClientEvent( type, client, bubbles, cancelable );
        }
        
        public override function toString():String
        {
            return formatToString( "ClientEvent", "client", "type", "bubbles", "cancelable" );
        }
    }
}