package library.circulate.nodes
{
    import library.circulate.NetworkNode;
    import library.circulate.NodeType;
    
    public class SwarmNode implements NetworkNode
    {
        private var _type:NodeType = NodeType.swarm;
        
        public function SwarmNode()
        {
        }
        
        public function get type():NodeType { return _type; }
    }
}