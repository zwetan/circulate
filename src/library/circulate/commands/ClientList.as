package library.circulate.commands
{
    import core.reflect.getClassName;
    
    import flash.net.registerClassAlias;
    
    import library.circulate.NetworkClient;
    import library.circulate.NetworkCommand;
    import library.circulate.NetworkNode;
    import library.circulate.NetworkSystem;
    import library.circulate.clients.Client;
    import library.circulate.networks.Network;
    
    registerClassAlias( "library.circulate.commands.ClientList", ClientList );
    
    public class ClientList implements NetworkCommand
    {
        private var _destination:String = "";
        
        public var clients:Vector.<NetworkClient>;
        
        public function ClientList( clients:Vector.<NetworkClient> = null )
        {
            clients = clients;
        }
        
        public function get name():String { return getClassName( this ); }
        
        public function get destination():String { return _destination; }
        public function set destination( value:String ):void { _destination = value; }
        
        public function get isRouted():Boolean
        {
            if( destination != "" )
            {
                return true;
            }
            
            return false;
        }
        
        public function execute( network:NetworkSystem, node:NetworkNode ):void
        {
            var _log:Function = network.writer;
//                _log( "command [" + name + "]" );
//                _log( "  |_ clients: " + clients );
            
            if( clients )
            {
                trace( "received list of " + clients.length + " clients:" );
                var i:uint;
                for( i=0; i<clients.length; i++ )
                {
                    trace( i + " : " + Client(clients[i]).toString() );
                }
            }
            
        }
    }
}