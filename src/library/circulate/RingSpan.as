package library.circulate
{
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
        
        public static function getAngle( ringspan:String ):uint
        {
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
            
            return (ratio) * ((360/15)/2);
        }
        
        public function RingSpan()
        {
        }
           
    }
}