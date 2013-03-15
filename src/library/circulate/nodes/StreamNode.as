package library.circulate.nodes
{
    import core.strings.startsWith;
    
    import flash.events.EventDispatcher;
    import flash.events.NetStatusEvent;
    import flash.net.GroupSpecifier;
    import flash.net.NetGroup;
    import flash.net.NetStream;
    import flash.utils.Dictionary;
    
    import library.circulate.NetworkClient;
    import library.circulate.NetworkCommand;
    import library.circulate.NetworkNode;
    import library.circulate.NetworkSystem;
    import library.circulate.NodeType;
    import library.circulate.networks.Network;
    
    public class StreamNode extends EventDispatcher implements NetworkNode
    {
        protected var _type:NodeType        = null;
        protected var _name:String          = "";
        protected var _joined:Boolean;
        protected var _streamAddress:String = "";
        
        protected var _network:NetworkSystem;
        protected var _stream:NetStream;
        protected var _specifier:GroupSpecifier;
        
        public function StreamNode( network:NetworkSystem, name:String = "", specifier:GroupSpecifier = null )
        {
            if( !specifier )
            {
                specifier = Network.getDefaultGroupSpecifier( name, network.config.IPMulticastAddress );
            }
            
            _network   = network;
            _name      = name;
            _specifier = specifier;
            
            _reset();
            
            _log( "StreamNode.ctor( \"" + name + "\" )" );
        }
        
        //--- events ---
        
        private function onNetStatus( event:NetStatusEvent ):void
        {
            var code:String   = event.info.code;
            var reason:String = "";
            
            _log( "StreamNode.onNetStatus( " + event.info.code + " )" );
            
            switch( code )
            {
                /* ---- NetStream ---- */
                
                
                /* The P2P connection was closed successfully.
                   The info.stream property indicates which stream has closed.
                   
                   Note: Not supported in AIR 3.0 for iOS.
                */
                case "NetStream.Connect.Closed": // event.info.stream
                
                /* The P2P connection attempt failed.
                   The info.stream property indicates which stream has failed.
                   Note: Not supported in AIR 3.0 for iOS.
                */
                case "NetStream.Connect.Failed": // event.info.stream
                
                /* The P2P connection attempt did not have permission to access the other peer.
                   The info.stream property indicates which stream was rejected.
                   
                   Note: Not supported in AIR 3.0 for iOS.
                */
                case "NetStream.Connect.Rejected": // event.info.stream
                
                reason = code.split( "." ).pop();
                doStreamNodeDisconnect( event.info.stream as NetStream, reason.toLowerCase() );
                break;
                
                /* The P2P connection attempt succeeded.
                   The info.stream property indicates which stream has succeeded.
                   
                   Note: Not supported in AIR 3.0 for iOS.
                */
                case "NetStream.Connect.Success": // event.info.stream
                doStreamNodeConnect( event.info.stream as NetStream );
                break;
                
            }
            
        }
        
        
        //--- netstatus actions ---
        
        /* note:
           By convention, to avoidto confuse those methods with event methods
           we would name them "doSomething" (instead of "onSomething")
           
           We keep them private for now, but we could make them protected.
        */
        
        private function doStreamNodeConnect( netstream:NetStream ):void
        {
            _log( "StreamNode.doStreamNodeConnect( " + netstream + " )" );
        }
        
        private function doStreamNodeDisconnect( netstream:NetStream, message:String = "" ):void
        {
            _log( "StreamNode.doStreamNodeDisconnect( " + netstream + ", " + message + " )" );
        }
        
        //--- private ---
        
        private function _log( message:String ):void
        {
            var log:Function = _network.writer;
            
//            if( startsWith( message, ">" ) )
//            {
//                log( message );
//            }

            log( message );
        }
        
        private function _reset():void
        {
            _log( "StreamNode._reset()" );
            
            _joined    = false;
            //_isElected = false;
            //_clients   = new Vector.<NetworkClient>();
        }
        
        private function _destroy():void
        {
            //_clients = null;
        }
        
        
        //--- public ---
        
        /* note:
           what we can consider the public API
           or the implementation of NetworkNode
        */
        
        public function get type():NodeType { return _type; }
        public function get name():String { return _name; }
        public function get specificier():GroupSpecifier { return _specifier; }
        public function get group():NetGroup { return null; }
        public function get stream():NetStream { return _stream; }
        public function get joined():Boolean { return _joined; }
        public function get isElected():Boolean { return false; }
        public function get isFullMesh():Boolean { return false; }
        public function get groupAddress():String { return ""; }
        public function get streamAddress():String { return _streamAddress; }
        
        public function get clients():Vector.<NetworkClient>
        {
            return null;
        }
        
        public function get estimatedMemberCount():uint
        {
            return 0;
        }
        
        
        public function findClientByPeerID(peerID:String):NetworkClient
        {
            return null;
        }
        
        public function addLocalClient():void
        {
        }
        
        public function removeLocalClient():void
        {
        }
        
        public function join( password:String = "" ):void
        {
            _log( "StreamNode.join( " + password + " )" );
            
            if( _joined || _stream )
            {
                trace( "stream already joined" );
                return;
            }
            
            if( password != "" )
            {
                _stream = new NetStream( _network.connection, _specifier.groupspecWithAuthorizations() );
            }
            else
            {
                _stream = new NetStream( _network.connection, _specifier.groupspecWithoutAuthorizations() );
            }
            
            _stream.addEventListener( NetStatusEvent.NET_STATUS, onNetStatus );
        }
        
        public function leave():void
        {
            _log( "StreamNode.leave()" );
            
            _stream.close();
        }
        
        public function subscribe( name:String ):void
        {
            _log( "StreamNode.subscribe( " + name + " )" );
            
            if( _joined )
            {
                _streamAddress = name;
                _stream.play( name );
            }
            else
            {
                trace( "you need to join the node before being able to subscribe" );
            }
        }
        
        public function publish( name:String ):void
        {
            _log( "StreamNode.publish( " + name + " )" );
            
            if( _joined )
            {
                _streamAddress = name;
                _stream.publish( name );
            }
            else
            {
                trace( "you need to join the node before being able to publish" );
            }
        }
        
        public function sendToAll( command:NetworkCommand ):void
        {
            
        }
        
        public function sendTo( peerID:String, command:NetworkCommand ):void
        {
            
        }
        
        public function sendToUser( name:String, command:NetworkCommand ):void
        {
            
        }
        
        public function sendToGroup( address:String, command:NetworkCommand ):void
        {
            
        }
        
        public function destroy():void { _destroy(); }
    }
}