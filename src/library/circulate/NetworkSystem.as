package library.circulate
{
    import flash.events.IEventDispatcher;
    import flash.net.NetConnection;
    
    /**
    * 
    */
    public interface NetworkSystem extends IEventDispatcher
    {
        function get config():NetworkConfiguration;
        function get type():NetworkType;
        
        function get enableErrorChecking():Boolean;
        function set enableErrorChecking( value:Boolean ):void;
        
        function get writer():Function;
        function set writer( value:Function ):void;
        
        function get connection():NetConnection;
        function get client():NetworkClient;
        function get nodes():Vector.<NetworkNode>;
        function get commandCenter():NetworkNode;
        
        function get connected():Boolean;
        function get estimatedTotalMember():uint;
        function get knownTotalMember():uint;
        
        function connect( server:String = "", key:String = "" ):void;
        function disconnect():void;
        
        function createNode( name:String, type:NodeType = null ):void;
        function hasNode( name:String ):Boolean;
        function joinNode( name:String ):void;
        function leaveNode( name:String ):void;
        
        function sendCommandToNode( command:NetworkCommand, node:NetworkNode = null ):void;
        //function resetTimeout():void;
    }
}