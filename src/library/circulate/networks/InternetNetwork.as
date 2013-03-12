package library.circulate.networks
{
    import library.circulate.Network;
    import library.circulate.NetworkConfiguration;
    import library.circulate.NetworkType;
    
    /**
    * 
    */
    public class InternetNetwork extends Network
    {
        private var _server:String;
        
        public function InternetNetwork( server:String = "", config:NetworkConfiguration = null )
        {
            super( NetworkType.internet, config );
            
            _server = server;
        }
        
        public override function connect( server:String = "", key:String = ""):void
        {
            if( server == "" ) { server = _server; }
            
            super.connect( server, key );
        }
        
    }
}