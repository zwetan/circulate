package library.circulate
{
    import core.maths.radiansToDegrees;

    public class RingSpan
    {
        public static const span_0_1:String = "0_1";
        public static const span_1_2:String = "1_2";
        public static const span_2_3:String = "2_3";
        public static const span_3_4:String = "3_4";
        public static const span_4_5:String = "4_5";
        public static const span_5_6:String = "5_6";
        public static const span_6_7:String = "6_7";
        public static const span_7_8:String = "7_8";
        public static const span_8_9:String = "8_9";
        public static const span_9_A:String = "9_A";
        public static const span_A_B:String = "A_B";
        public static const span_B_C:String = "B_C";
        public static const span_C_D:String = "C-D";
        public static const span_D_E:String = "D_E";
        public static const span_E_F:String = "E_F";
        
        private static var _MPI:Number = Math.PI/180;
        
        //return the starting angle as radian
        public static function getStartAngle( startAt:uint = 270 ):Number
        {
            var startRadians:Number = startAt * _MPI;
            
            return startRadians;
        }
        
        //return the incremented angle as radian
        //based on the total number of spans over the max arc (eg. full circle is 360)
        public static function getIncrementAngle( arc:Number = 360,
                                                  totalSpans:uint = 15 ):Number
        {
            var incrementAngle:Number = arc/totalSpans;
            var incrementRadians:Number = incrementAngle * _MPI;
            
            return incrementRadians;
        }
        
        //return the incremented angle as radian at a particular position on the ring
        public static function getIncrementAngleAt( ringPosition:uint = 0, spanPosition:int = 0,
                                                    arc:Number = 360, totalSpans:uint = 15,
                                                    startAt:uint = 270 ):Number
        {
            var startRadians:Number     = getStartAngle( startAt );
            var incrementRadians:Number = getIncrementAngle( arc, totalSpans );
            var halfRadians:Number      = incrementRadians/2;
            
            var i:uint;
            for( i=0 ; i<ringPosition; i++ )
            {
                startRadians += incrementRadians;
            }
            
            var result:Number;
            if( spanPosition < 0 )
            {
                result = startRadians - (halfRadians*2);
            }
            else if( spanPosition == 0 )
            {
                result = startRadians - halfRadians;
            }
            else if( spanPosition > 0 )
            {
                result = startRadians;
            }
            
            return result;
        }
        
        
        //return the angle position of the span as radian
        public static function getAngle( ringspan:String, position:int = 0 ):Number
        {
            /* note:
               positioncan be either
                 -1 : align on the left of the span
                  0 : align on the center of the span
                  1 : align on the rightof the span
               
               eg. if your span is 5_6
               -1 is the position on the 5
                0 is the position between 5 and 6
                1 is the position on the 6 
            */
            
            var ratio:uint = 0;
            
            switch( ringspan )
            {
                case span_0_1:
                ratio = 1;
                break;
                
                case span_1_2:
                ratio = 2;
                break;
                
                case span_2_3:
                ratio = 3;
                break;
                
                case span_3_4:
                ratio = 4;
                break;
                
                case span_4_5:
                ratio = 5;
                break;
                
                case span_5_6:
                ratio = 6;
                break;
                
                case span_6_7:
                ratio = 7;
                break;
                
                case span_7_8:
                ratio = 8;
                break;
                
                case span_8_9:
                ratio = 9;
                break;
                
                case span_9_A:
                ratio = 10;
                break;
                
                case span_A_B:
                ratio = 11;
                break;
                
                case span_B_C:
                ratio = 12;
                break;
                
                case span_C_D:
                ratio = 13;
                break;
                
                case span_D_E:
                ratio = 14;
                break;
                
                case span_E_F:
                ratio = 15;
                break;
            }
            
            return getIncrementAngleAt( ratio, position );
        }
        
        public function RingSpan()
        {
        }
           
    }
}