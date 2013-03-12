package library.circulate.events
{
    import flash.events.Event;
    
    import library.circulate.NetworkClient;
    
    public class NeighborEvent extends Event
    {
        /** dispatched when a neighbor connect to a NetworkNode */
        public static const CONNECT:String    = "neighbor_connect";
        
        /** dispatched when a neighbor disconnect from a NetworkNode */
        public static const DISCONNECT:String = "neighbor_disconnect";
        
        public var client:NetworkClient;
        
        public function NeighborEvent( type:String, client:NetworkClient,
                                       bubbles:Boolean = false, cancelable:Boolean = false )
        {
            super( type, bubbles, cancelable );
            this.client = client;
        }
        
        public override function clone():Event
        {
            return new NeighborEvent( type, client, bubbles, cancelable );
        }
        
        public override function toString():String
        {
            return formatToString( "NeighborEvent", "client", "type", "bubbles", "cancelable" );
        }
    }
}