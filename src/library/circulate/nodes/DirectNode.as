package library.circulate.nodes
{
    import flash.net.GroupSpecifier;
    import flash.net.NetGroup;
    import flash.utils.Dictionary;
    
    import library.circulate.NetworkClient;
    import library.circulate.NetworkCommand;
    import library.circulate.NetworkNode;
    import library.circulate.NodeType;
    
    /* note:
       One-to-one direct connections
       
       Publish:
       var ns:NetStream = new NetStream( netConnection, NetStream.DIRECT_CONNECTIONS );
           ns.publish( "stream" );
       
       Play:
       var ns:NetStream = new NetStream( netConnection, peerID );
           ns.play( "stream" );
       
       
    */
    public class DirectNode implements NetworkNode
    {
        public function DirectNode()
        {
        }
        
        public function get type():NodeType
        {
            return null;
        }
        
        public function get name():String
        {
            return null;
        }
        
        public function get specificier():GroupSpecifier
        {
            return null;
        }
        
        public function get group():NetGroup
        {
            return null;
        }
        
        public function get joined():Boolean
        {
            return false;
        }
        
        public function get clients():Vector.<NetworkClient>
        {
            return null;
        }
        
        public function get sent():Dictionary
        {
            return null;
        }
        
        public function findClientByPeerID(peerID:String):NetworkClient
        {
            return null;
        }
        
        public function addLocalClient():void
        {
        }
        
        public function removeLocalClient():void
        {
        }
        
        public function join(password:String=""):void
        {
        }
        
        public function leave():void
        {
        }
        
        public function sendToAll(command:NetworkCommand):void
        {
        }
    }
}