package library.circulate
{
    public class AutomaticDistributedElection
    {
        public static function isInRingSpan( target:String, rangeFrom:String, rangeTo:String ):Boolean
        {
            target    = target.toLowerCase();
            rangeFrom = rangeFrom.toLowerCase();
            rangeTo   = rangeTo.toLowerCase();
            
            if( rangeTo < rangeFrom )
            {
            	return isInRingSpan( target, rangeFrom,             RingPosition.addressF )
            	    || isInRingSpan( target, RingPosition.address0, rangeTo );
            }
            
            return (target >= rangeFrom) && (target <= rangeTo);
        }
        
    /*
                       
                          0000
                           |
                     ******|******
                  *********************
               ******             *******
            *******                 ********
           *****                      ********
          *****                           *****
          *****                           *****
         ******                           ****** 
          *****                           *****
          *****                           *****
           *****                       *******
            *******                 ********
               /*****             *******\
       2/3 aaaa   *********************   5555 1/3
                     *************
                        *******
    */
        public static function triangulate( rangeFrom:String, rangeTo:String ):Boolean
        {
            return ( isInRingSpan( RingPosition.address0, rangeFrom, rangeTo)
				  || isInRingSpan( RingPosition.address5, rangeFrom, rangeTo)
				  || isInRingSpan( RingPosition.addressA, rangeFrom, rangeTo) );
        }
        
        public function AutomaticDistributedElection()
        {
        }
        
    }
}