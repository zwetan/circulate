package library.circulate.nodes
{
    import core.strings.format;
    
    import flash.events.NetStatusEvent;
    import flash.net.GroupSpecifier;
    import flash.net.NetGroup;
    
    import library.circulate.Network;
    import library.circulate.NetworkNode;
    import library.circulate.NetworkStrings;
    import library.circulate.NodeType;
    
    public class BaseNode implements NetworkNode
    {
        protected var _type:NodeType  = null;
        protected var _name:String    = "";
        protected var _joined:Boolean = false;
        
        protected var _network:Network;
        protected var _group:NetGroup;
        protected var _specifier:GroupSpecifier;
        
        public function BaseNode( network:Network, name:String = "", specifier:GroupSpecifier = null )
        {
            if( !specifier )
            {
                specifier = Network.getDefaultGroupSpecifier( name, network.config.IPMulticastAddress );
            }
            
            _network   = network;
            _name      = name;
            _specifier = specifier;
        }
        
//        private function onNetStatus( event:NetStatusEvent ):void
//        {
//            var code:String   = event.info.code;
//            var reason:String = "";
//            
//            //trace( dump( event, true ) );
//            
//            var log:Function = _network.writer;
//            
//            log( _type.toString() + " netstatus code: " + event.info.code );
//            
//            switch( code )
//            {
//                
//                
//            }
//            
//        }
        
        public function get type():NodeType { return _type; }
        public function get name():String { return _name; }
        public function get specificier():GroupSpecifier { return _specifier; }
        public function get group():NetGroup { return _group; }
        public function get joined():Boolean { return _joined; }
        
        public function join( password:String = "" ):void
        {
            if( _joined || _group )
            {
                var message:String = format( NetworkStrings.groupAlreadyJoined, {name:name} );
                trace( message );
                return;
            }
            
            if( password != "" )
            {
                _group = new NetGroup( _network.connection, _specifier.groupspecWithAuthorizations() );
            }
            else
            {
                _group = new NetGroup( _network.connection, _specifier.groupspecWithoutAuthorizations() );
            }
            
            _group.addEventListener( NetStatusEvent.NET_STATUS, _network.onNetStatus );
            _joined = true;
        }
        
        public function leave():void
        {
            if( !_joined )
            {
                var message:String = format( NetworkStrings.groupNotJoined, {name:name} );
                trace( message );
                return;
            }
            
            _group.close();
            _group.removeEventListener( NetStatusEvent.NET_STATUS, _network.onNetStatus );
            _group    = null;
            _joined   = false;
        }
    }
}