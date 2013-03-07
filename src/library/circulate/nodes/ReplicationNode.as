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
       var ng:NetGroup = new NetGroup( netConnection, groupspec );
       
       Object Replication
       - netGroup.addHaveObjects()
       - netGroup.addWantObjects()
       - netGroup.removeHaveObjects()
       - netGroup.removeWantObjects()
       - netGroup.writeRequestedObject()
       - netGroup.replicationStrategy (lowest first, rarest first)
       - Events
         - NetGroup.Replication.Request
         - NetGroup.Replication.Fetch.Result
         - NetGroup.Replication.Fetch.SendNotify
         - NetGroup.Replication.Fetch.Failed
       
       
       NetGroupReplicationStrategy.LOWEST_FIRST
       Specifies that when fetching objects from a neighbor to satisfy a want,
       the objects with the lowest index numbers are requested first.
       
       NetGroupReplicationStrategy.RAREST_FIRST
       Specifies that when fetching objects from a neighbor to satisfy a want,
       the objects with the fewest replicas among all the neighbors are requested first.
       
    */
    public class ReplicationNode implements NetworkNode
    {
        public function ReplicationNode()
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