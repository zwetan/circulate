package library.circulate.utils
{
    public function traceConnectivityResults( info:Object, writer:Function = null ):void
    {
        if( writer == null ) { writer = trace; }
        
        if( info == null )
        {
            writer( "not connectivity results found." );
            return;
        }
        
        writer( "connectivity results:" );
        if( info.publicAddress != undefined )
        {
            writer( " | Public IP address: " + info.publicAddress );
        }
        
        if( info.localAddresses != undefined )
        {
            writer( " | Reported IP addresses: " );
            writer( " |   |  " );
            var i:uint;
            for( i=0; i<info.localAddresses.length; i++ )
            {
                writer( " |  [" + i + "] " + info.localAddresses[i] );
            }
            writer( " |  " );
        }
        
        writer( "public address is local: " + info.publicAddressIsLocal );
        writer( "receive same address same port allowed: " + info.receiveSameAddressSamePortAllowed );
        writer( "receive same address different port allowed: " + info.receiveSameAddressDifferentPortAllowed );
        writer( "receive different address different port allowed: " + info.receiveDifferentAddressDifferentPortAllowed );
        writer( "send after introduction allowed: " + info.sendAfterIntroductionAllowed );
        writer( "preserves source address: " + info.sendAfterIntroductionPreservesSourceAddress );
        writer( "preserves source port: " + info.sendAfterIntroductionPreservesSourcePort );
        writer( "public port matches local port: " + info.publicPortMatchesLocalPort );
        writer( "" );
        writer( "Analysis Complete." );
        
    }
}