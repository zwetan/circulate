package library.circulate.nodes
{
    import library.circulate.Network;
    import library.circulate.NodeType;
    
    public class ChatNode extends BaseNode
    {
        
        public function ChatNode( network:Network, name:String = "" )
        {
            super( network, name );
            _type = NodeType.chat;
        }
        
    }
}