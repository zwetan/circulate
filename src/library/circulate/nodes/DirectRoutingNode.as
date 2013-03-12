package library.circulate.nodes
{
    import flash.net.GroupSpecifier;
    import flash.net.NetGroupReceiveMode;
    
    import library.circulate.networks.Network;
    
    /* note:
       
       Directed Routing
       - netGroup.sendToNearest()
       - netGroup.sendToNeighbor()
       - netGroup.sendToAllNeighbors()
       - netGroup.receiveMode
         - NetGroupReceiveMode.EXACT (default)
         - NetGroupReceiveMode.NEAREST
       - NetGroup.SendTo.Notifyevent
       
       
       info:
       
       GroupSpecifier.routingEnabled = true
       Send a message directly to one or more peers in a group
       Reliable, in-order delivery mode
       
       
       automatic distributed election:
       
       Use local coverage
       Consistently select O(1) subset of members for special responsibilities
       Gotcha when electing more than one peer
       
       
       detail:
       
       NetGroupReceiveMode.EXACT
       Specifies that this node accepts local messages from neighbors only
       if the address the neighbor uses matches this node's address exactly.
       
       NetGroupReceiveMode.NEAREST
       Specifies that this node accepts local messages from neighbors that
       send messages to group addresses that don't match this node's address exactly.
       
       
       NetGroupSendMode.NEXT_DECREASING
       Specifies the neighbor with the nearest group address in the decreasing direction.
       
       NetGroupSendMode.NEXT_INCREASING	
       Specifies the neighbor with the nearest group address in the increasing direction.
       
       
       NetGroupSendResult.ERROR
       Indicates an error occurred (such as no permission)
       when using a Directed Routing method.
       
       NetGroupSendResult.NO_ROUTE
       Indicates no neighbor could be found to route the message
       toward its requested destination.
       
       NetGroupSendResult.SENT
       Indicates that a route was found for the message
       and it was forwarded toward its destination.
       
    */
    public class DirectRoutingNode extends Node
    {
        public function DirectRoutingNode( network:Network, name:String = "" )
        {
            var specifier:GroupSpecifier = Network.getDefaultGroupSpecifier( name, network.config.IPMulticastAddress );
                specifier.routingEnabled = true;
            
            super( network, name, specifier );
        }
        
    }
}