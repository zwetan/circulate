package library.circulate.networks
{
    import library.circulate.NetworkConfiguration;
    import library.circulate.NetworkType;
    
    /**
    * 
    */
    public class AdobeCirrusTestNetwork extends Network
    {
        public function AdobeCirrusTestNetwork( config:NetworkConfiguration = null )
        {
            if( !config )
            {
                config = Network.getDefaultConfiguration();
                config.testServer = "cc.rtmfp.net";
            }
            
            super( NetworkType.test, config );
        }
    }
}