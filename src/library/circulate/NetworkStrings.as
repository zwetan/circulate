package library.circulate
{
    public class NetworkStrings
    {
        public function NetworkStrings()
        {
        }
        
        public static var serverKeyEmpty:String          = "your server key is empty"; 
        
        public static var networkAlreadyConnected:String = "Already connected, use the command 'connectToGroup()' or 'disconnect()'.";
        public static var networkConnectingTo:String     = "Connecting to \"{server}\" ...";
        
        public static var groupAlreadyJoined:String      = "Group '{name}' already joined.";
        public static var groupNotJoined:String          = "Group '{name}' was not joined.";
        public static var groupNotFound:String           = "Group '{name}' was not found.";
        public static var groupNeedConnectFirst:String   = "You need to connect first before joining a group.";
        public static var groupAddAndJoin:String         = "Adding and joining group '{name}'.";
        public static var groupJoining:String            = "Joining group '{name}' ...";
        
    }
}