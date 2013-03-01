package library.circulate.nodes
{
    import library.circulate.Network;
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