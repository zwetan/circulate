package library.circulate.nodes
{
    import flash.net.GroupSpecifier;
    import flash.net.NetGroupReceiveMode;
    
    import library.circulate.Network;
    
    /* note:
       
       Posting
       - netGroup.post( object )
       - NetGroup.Posting.Notifyevent
       
    */
    public class PostingNode extends BaseNode
    {
        public function PostingNode( network:Network, name:String = "" )
        {
            var specifier:GroupSpecifier = Network.getDefaultGroupSpecifier( name, network.config.IPMulticastAddress );
                specifier.postingEnabled = true;
            
            super( network, name, specifier );
        }
        
        protected override function onJoinNode():void
        {
            _group.receiveMode = NetGroupReceiveMode.NEAREST;
            //NetGroupSendMode.NEXT_INCREASING
        }
        
    }
}