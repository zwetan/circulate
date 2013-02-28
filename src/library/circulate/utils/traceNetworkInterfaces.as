package library.circulate.utils
{
    import flash.system.ApplicationDomain;

    public function traceNetworkInterfaces( writer:Function = null ):void
    {
        if( writer == null ) { writer = trace; }
        
        if( isAIR() )
        {
            var NINTC:Class = ApplicationDomain.currentDomain.getDefinition( "flash.net.NetworkInterface" ) as Class;
            var NINFC:Class = ApplicationDomain.currentDomain.getDefinition( "flash.net.NetworkInfo" ) as Class;
            
            if( NINTC && NINFC )
            {
                if( !NINFC.isSupported )
                {
                    writer( "networkinfo is not supported." );
                    return;
                }
                else
                {
                    writer( "networkinfo is supported." );
                }
            }
            
        }
        else
        {
            writer( "networkinfo is not supported." );
        }
    }
}