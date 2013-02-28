package library.circulate
{
    import flash.utils.ByteArray;

    public class Packet
    {
        static private var _SEQUENCE:uint = 0;
        
        /* unique id of the packet
           
           because RTMFP consider that the same message in "data"
           should not be sent twice
           eg.
           message1 = { text: "hello world" }; //sent
           message2 = { text: "hello world" }; //not sent
           
           so with a unique id, everything is sent
           message1 = { id:1001, text: "hello world" }; //sent
           message2 = { id:1002, text: "hello world" }; //sent too
        */
        public var id:uint;
        
        /* the serialized data of the command
           
           we only use packet for convenience,
           to always serialise/deserialise
           the same Packet type
        */
        public var data:ByteArray;
        
        public function Packet( data:ByteArray )
        {
            this.id   = _incrementSequence();
            this.data = data;
        }
        
        private function _incrementSequence():uint
        {
            if( (_SEQUENCE+1) >= uint.MAX_VALUE )
            {
                _SEQUENCE = 0;
            }
            else
            {
                _SEQUENCE++;
            }
            
            return _SEQUENCE;
        }
        
    }
}