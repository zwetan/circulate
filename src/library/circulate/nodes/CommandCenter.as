package library.circulate.nodes
{
    import flash.events.NetStatusEvent;
    import flash.net.NetGroup;
    
    import library.circulate.Network;
    import library.circulate.NetworkNode;
    import library.circulate.NetworkType;
    import library.circulate.NodeType;
    
    public class CommandCenter extends BaseNode
    {
        
        public function CommandCenter( network:Network, name:String = "" )
        {
            super( network, name );
            _type = NodeType.command;
        }
                
    }
}