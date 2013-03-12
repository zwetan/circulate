package library.circulate.networks
{
    import library.circulate.Network;
    import library.circulate.NetworkConfiguration;
    import library.circulate.NetworkType;
    
    /**
    * 
    */
    public class AdobeCirrusNetwork extends Network
    {
        public function AdobeCirrusNetwork( developerKey:String = "", config:NetworkConfiguration = null )
        {
            if( !config )
            {
                config = Network.getDefaultConfiguration();
                config.adobeServer = "p2p.rtmfp.net";
                config.serverKey   = developerKey;
            }
            
            super( NetworkType.internet, config );
        }
    }
}