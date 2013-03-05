package library.circulate
{
    import core.dump;
    
    /**
    * Configuration class for the library.
    */
    public class NetworkConfiguration
    {
        private var _config:Object;
        
        public function NetworkConfiguration( config:Object = null )
        {
            _config = {};
            
            if( config )
            {
                load( config );
            }
        }
        
        public function load( config:Object ):void
        {
            for( var member:String in config )
            {
                _config[member] = config[member] ;
            }
        }
        
        public function toSource():String
        {
            return dump( _config, true );
        }
        
        
        /* Network Configuration */
        
        /** The default username. */
        public function get enableErrorChecking():Boolean { return _config.enableErrorChecking; }
        /** @private */
        public function set enableErrorChecking( value:Boolean ):void { _config.enableErrorChecking = value; }
        
        /** The default username. */
        public function get loopback():Boolean { return _config.loopback; }
        /** @private */
        public function set loopback( value:Boolean ):void { _config.loopback = value; }
        
        /** The default username. */
        public function get compressPacket():Boolean { return _config.compressPacket; }
        /** @private */
        public function set compressPacket( value:Boolean ):void { _config.compressPacket = value; }
        
        /** The default username. */
        public function get wrapCommandIntoPacket():Boolean { return _config.wrapCommandIntoPacket; }
        /** @private */
        public function set wrapCommandIntoPacket( value:Boolean ):void { _config.wrapCommandIntoPacket = value; }
        
        /** The default username. */
        public function get username():String { return _config.username; }
        /** @private */
        public function set username( value:String ):void { _config.username = value; }
        
        /** The default username. */
        public function get localArea():String { return _config.localArea; }
        /** @private */
        public function set localArea( value:String ):void { _config.localArea = value; }
        
        /** The default username. */
        public function get testServer():String { return _config.testServer; }
        /** @private */
        public function set testServer( value:String ):void { _config.testServer = value; }
        
        /** The default username. */
        public function get adobeServer():String { return _config.adobeServer; }
        /** @private */
        public function set adobeServer( value:String ):void { _config.adobeServer = value; }
        
        /** The default username. */
        public function get serverKey():String { return _config.serverKey; }
        /** @private */
        public function set serverKey( value:String ):void { _config.serverKey = value; }
        
        /** The default username. */
        public function get commandCenter():String { return _config.commandCenter; }
        /** @private */
        public function set commandCenter( value:String ):void { _config.commandCenter = value; }
        
        /** The default username. */
        public function get IPMulticastAddress():String { return _config.IPMulticastAddress; }
        /** @private */
        public function set IPMulticastAddress( value:String ):void { _config.IPMulticastAddress = value; }
        
        
        
        /** The default username. */
        public function get maxPeerConnections():uint { return _config.maxPeerConnections; }
        /** @private */
        public function set maxPeerConnections( value:uint ):void { _config.maxPeerConnections = value; }
        
        /** The default username. */
        public function get connectionTimeout():uint { return _config.connectionTimeout; }
        /** @private */
        public function set connectionTimeout( value:uint ):void { _config.connectionTimeout = value; }
        
    }
}