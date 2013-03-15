package library.circulate.data
{
    import core.hash.elf;
    
    import flash.net.registerClassAlias;
    import flash.utils.ByteArray;
    
    registerClassAlias( "library.circulate.UniquePacket", UniquePacket );
    
    public class UniquePacket
    {
        private static var _SEQUENCE:uint = 0;
        
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
        
        public function UniquePacket()
        {
            update();
        }
        
        /* unique id with different instances, networks, etc.
           
           if we were using only a 'sequence'
           we could not synchronize it with all the instances
           
           instance1: new Packet(); //id = 123
           instance2: new Packet(); //id = 456
           
           so we add a "random" with the current timestamp
           
           but as it is not random enough and we want to be sure
           we stay within 32bits, we then use a hash function
           
           so far we use ELF, it could be any other 32bits hash function
        */
        private function _update():uint
        {
            var now:Date        = new Date();
            var sequence:uint   = _incrementSequence();
            var bytes:ByteArray = new ByteArray();
                bytes.writeUnsignedInt( now.valueOf() );
                bytes.writeUnsignedInt( sequence );
            var hash:uint = elf( bytes );
            return hash; 
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
        
        public function update():void
        {
            this.id = _update();
        }
    }
}