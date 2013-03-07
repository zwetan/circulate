package library.circulate.nodes
{
    import flash.net.GroupSpecifier;
    import flash.net.NetGroupReceiveMode;
    
    import library.circulate.Network;
    
    public class MixedRoutingNode extends BaseNode
    {
        public function MixedRoutingNode( network:Network, name:String="" )
        {
            var specifier:GroupSpecifier = Network.getDefaultGroupSpecifier( name, network.config.IPMulticastAddress );
                specifier.postingEnabled = true;
                specifier.routingEnabled = true;
            
            super( network, name, specifier );
        }
        
        protected override function onJoinNode():void
        {
            _group.receiveMode = NetGroupReceiveMode.NEAREST;
            //NetGroupSendMode.NEXT_INCREASING
        }
    }
}