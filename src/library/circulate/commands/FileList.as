package library.circulate.commands
{
    import library.circulate.NetworkCommand;
    import library.circulate.NetworkNode;
    import library.circulate.NetworkSystem;
    
    /* note:
       to send a list of shared files
    */
    public class FileList implements NetworkCommand
    {
        public function FileList()
        {
        }
        
        public function get name():String
        {
            return null;
        }
        
        public function get destination():String
        {
            return null;
        }
        
        public function set destination(value:String):void
        {
        }
        
        public function get isRouted():Boolean
        {
            return false;
        }
        
        public function execute(network:NetworkSystem, node:NetworkNode):void
        {
        }
    }
}