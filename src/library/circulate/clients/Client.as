package library.circulate.clients
{
    import library.circulate.NetworkClient;
    
    public class Client implements NetworkClient
    {
        private var _username:String;
        private var _peerID:String;
        
        public function Client( username:String = "", peerID:String = "" )
        {
            _username = username;
            _peerID   = peerID;
        }
        
        public function get username():String { return _username; }
        public function set username( value:String ):void { _username = value; }
        
        public function get peerID():String { return _peerID; }
        public function set peerID(value:String):void { _peerID = value; }
        
        public function toString():String
        {
            return "["+username+"]";
        }
    }
}