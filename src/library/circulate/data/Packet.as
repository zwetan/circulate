package library.circulate.data
{
    import core.hash.elf;
    
    import flash.net.registerClassAlias;
    import flash.utils.ByteArray;
    
    registerClassAlias( "library.circulate.Packet", Packet );
    
    public class Packet extends UniquePacket
    {
        
        /* the serialized data of the command
           
           we only use packet for convenience,
           to always serialise/deserialise
           the same Packet type
        */
        public var data:ByteArray;
        
        public function Packet( data:ByteArray = null )
        {
            this.data = data;
        }
        
    }
}