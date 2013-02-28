package library.circulate.utils
{
    import flash.system.ApplicationDomain;

    public function getLocalUserName():String
    {
        var _local:String = "unknown";
        
        if( isAIR() )
        {
            var FILEC:Class = ApplicationDomain.currentDomain.getDefinition( "flash.filesystem.File" ) as Class;
            
            if( FILEC && ( "userDirectory" in FILEC ) )
            {
                return FILEC[ "userDirectory" ].name;
            }
        }
        
        return _local;
    }
}