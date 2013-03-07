package library.circulate.nodes
{
    import flash.net.GroupSpecifier;
    
    import library.circulate.Network;
    import library.circulate.NodeType;
    
    public class CommandCenter extends BaseNode
    {
        
        public function CommandCenter( network:Network, name:String = "" )
        {
            var specifier:GroupSpecifier = Network.getDefaultGroupSpecifier( name, network.config.IPMulticastAddress );
                specifier.routingEnabled = true;
                specifier.postingEnabled = true;
            
            super( network, name, specifier );
            //super( network, name );
            _type = NodeType.command;
        }
        
        //_group.receiveMode = NetGroupReceiveMode.NEAREST;
                
    }
}