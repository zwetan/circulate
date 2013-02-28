package library.circulate.nodes
{
    import library.circulate.NodeType;

    public class OneFileNode extends SwarmNode
    {
        private var _type:NodeType = NodeType.onefile;
        
        public function OneFileNode()
        {
            super();
        }
        
        public override function get type():NodeType { return _type; }
    }
}