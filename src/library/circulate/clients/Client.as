package library.circulate.clients
{
    import library.circulate.NetworkClient;
    
    public class Client implements NetworkClient
    {
        private var _username:String;
        private var _peerID:String;
        private var _address:String;
        private var _elected:Boolean;
        
        //record of when the user joined the node
        private var _arrivedTime:Date;
        
        //last time the user has been updated
        private var _idleTime:Date;
        
        public function Client( username:String = "",
                                peerID:String = "",
                                address:String = "",
                                elected:Boolean = false,
                                arrivedTime:Date = null,
                                idleTime:Date = null )
        {
            _username    = username;
            _peerID      = peerID;
            _address     = address;
            _elected     = elected;
            _arrivedTime = arrivedTime;
            _idleTime    = idleTime;
        }
        
        public function get username():String { return _username; }
        public function set username( value:String ):void { _username = value; }
        
        public function get peerID():String { return _peerID; }
        public function set peerID( value:String ):void { _peerID = value; }
        
        public function get address():String { return _address; }
        public function set address( value:String ):void { _address = value; }
        
        public function get elected():Boolean { return _elected; }
        public function set elected( value:Boolean ):void { _elected = value; }
        
        public function get arrivedTime():Date { return _arrivedTime; }
        public function set arrivedTime( value:Date ):void { _arrivedTime = value; }
        
        public function get idleTime():Date { return _idleTime; }
        public function set idleTime( value:Date ):void { _idleTime = value; }
        
        public function toString():String
        {
            return "["+username+"] (" + peerID.substr(0, 4) + "...)" ;
        }
    }
}