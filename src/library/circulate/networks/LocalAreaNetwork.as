package library.circulate.networks
{
    import library.circulate.NetworkConfiguration;
    import library.circulate.NetworkType;
    
    /**
    * 
    */
    public class LocalAreaNetwork extends Network
    {
        public function LocalAreaNetwork( config:NetworkConfiguration = null )
        {
            if( !config )
            {
                config = Network.getDefaultConfiguration();
                config.localArea = "rtmfp:";
            }
            
            super( NetworkType.local, config );
        }
    }
}