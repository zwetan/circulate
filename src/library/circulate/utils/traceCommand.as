package library.circulate.utils
{
    import library.circulate.NetworkCommand;

    public function traceCommand( command:NetworkCommand, writer:Function = null ):void
    {
        if( writer == null ) { writer = trace; }
        
        if( command )
        {
            writer( "command [" + command.name + "]" );
            writer( "  |_ destination: " + command.destination );
            writer( "  |_ isRouted: " + command.isRouted );
        }
    }
}