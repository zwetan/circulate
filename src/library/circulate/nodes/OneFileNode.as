package library.circulate.nodes
{
    import flash.net.GroupSpecifier;
    
    import library.circulate.NetworkSystem;
    import library.circulate.NodeType;
    import library.circulate.networks.Network;

    public class OneFileNode extends Node
    {
        private var _type:NodeType = NodeType.onefile;
        
        public function OneFileNode( network:NetworkSystem, name:String = "" )
        {
            var specifier:GroupSpecifier = Network.getDefaultGroupSpecifier( name, network.config.IPMulticastAddress );
                specifier.routingEnabled           = true;
                specifier.postingEnabled           = true;
                specifier.objectReplicationEnabled = true;
            
            super( network, name, specifier );
            _type = NodeType.onefile;
            
            _ctor();
        }
        
        
        //--- private ---
        
        private function _ctor():void
        {
            
        }
        
        private function _log( message:String ):void
        {
            var log:Function = _network.writer;
            
//            if( startsWith( message, ">" ) )
//            {
//                log( message );
//            }

            log( message );
        }
        
        
        protected override function doReplicationFetchFailed( index:Number ):void
        {
            _log( "OneFileNode.doReplicationFetchFailed( " + index + " )" );
        }
        
        protected override function doReplicationFetchResult( index:Number, data:Object ):void
        {
            _log( "OneFileNode.doReplicationFetchResult( " + index + ", " + data + " )" );
        }
        
        protected override function doReplicationFetchSendNotify( index:Number ):void
        {
            _log( "OneFileNode.doReplicationFetchSendNotify( " + index + " )" );
        }
        
        protected override function doReplicationRequest( index:Number, requestID:int ):void
        {
            _log( "OneFileNode.doReplicationRequest( " + index + ", " + requestID + " )" );
        }
        
    }
}