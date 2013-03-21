package library.circulate.commands
{
    import library.circulate.NetworkCommand;
    import library.circulate.NetworkNode;
    import library.circulate.NetworkSystem;
    
    /* note:
       to tell others you can share a file even if not already shared
    */
    public class HaveFile implements NetworkCommand
    {
        public function HaveFile()
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