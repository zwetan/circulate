package
{
    import core.maths.degreesToRadians;
    import core.maths.radiansToDegrees;
    
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.geom.ColorTransform;
    import flash.geom.Point;
    import flash.utils.Dictionary;
    
    import library.circulate.RingTopology;
    import library.circulate.NetworkClient;
    import library.circulate.RingSpan;
    
    public class UICommandCenter extends Sprite
    {
        //UI
        public var bg:Sprite;
        public var area:Sprite;
        
        public var centerPoint:Sprite;
        
        public function UICommandCenter()
        {
            super();
            
            if( stage )
            {
                onAddedToStage();
            }
            else
            {
                addEventListener( Event.ADDED_TO_STAGE, onAddedToStage );
            }
        }
        
        //---- events ----
        
        private function onAddedToStage( event:Event = null ):void
        {
            trace( "UICommandCenter.onAddedToStage()" );
            removeEventListener( Event.ADDED_TO_STAGE, onAddedToStage );
            main();
        }
        
        private function onResize( event:Event = null ):void
        {
            //area.x = stage.stageWidth/2;
            //area.y = stage.stageHeight/2;
            
            x = (stage.stageWidth)/2;
            y = (stage.stageHeight)/2;
        }
        
        private function _colorize( target:DisplayObject, color:uint ):void
        {
            var ct:ColorTransform = new ColorTransform();
                ct.color = color;
            
            target.transform.colorTransform = ct;
        }
        
        private function _getMarking():Sprite
        {
            var mark:Sprite = new Sprite();
                mark.graphics.clear();
                mark.graphics.beginFill( 0x000000, 1.0 );
                mark.graphics.drawRect( -3, -2, 6, 4 );
                mark.graphics.endFill();
            
            return mark;
        }
        
//        private function _drawMarkings():void
//        {
//            
//            var arc:Number = 360;
//            var total:uint = 15;
//            var p:Point;
//            var a:Number;
//            var angle:Number;
//            var i:uint;
//            
//            var mpi:Number = Math.PI/180;
//            var incrementAngle:Number;
//            var incrementRadians:Number;
//            var startRadians:Number;
//            
//            var startangle:Number   = 270;
////            var circleradius:Number = 120;
////            var diameter:Number     = circleradius*2;
//            
//            startRadians     = startangle * mpi;
//            incrementAngle   = arc/total;
//            incrementRadians = incrementAngle * mpi;
//            
//            for( i=0; i<total; i++ )
//            {
//                
////                p = new Point( Math.sin(startRadians) * circleradius,
////                               Math.cos(startRadians) * circleradius );
//                
//                trace( "rad = " + startRadians );
//                trace( "deg = " + Math.round(radiansToDegrees( startRadians )) );
//                p = Point.polar( 130, startRadians );
//                
//                if( i == 0 )
//                {
//                    graphics.lineStyle( 1, 0xff0000 );
//                }
//                else
//                {
//                    graphics.lineStyle( 1, 0x000000 );
//                }
//                
//                graphics.moveTo( 0, 0 );
//                graphics.lineTo( p.x, p.y );
//                startRadians += incrementRadians; //+ is cclockwise, - is counterclockwise
//            }
//            
//            graphics.endFill();
//        }
        
        
        private function _drawMarkings():void
        {
            var arc:Number        = 360;
            var total:uint        = 15;
            var startangle:Number = 270;
            var distance:uint     = 130;
            
            var i:uint;
            var angle:Number;
            var p:Point;
            
            for( i=0; i<total; i++ )
            {
                angle = RingSpan.getIncrementAngleAt( i, 1, arc, total, startangle );
                p = Point.polar( distance, angle );
                
                if( i == 0 )
                {
                    graphics.lineStyle( 1, 0xff0000 );
                }
                else
                {
                    graphics.lineStyle( 1, 0x000000 );
                }
                
                graphics.moveTo( 0, 0 );
                graphics.lineTo( p.x, p.y );
            }
            
            graphics.endFill();
        }
        
        private function _draw():void
        {
            bg = new Sprite();
            bg.graphics.clear();
            bg.graphics.lineStyle( 1, 0x000000, 0.2 );
            //bg.graphics.beginFill( 0x000000, 0.2 );
            bg.graphics.drawRect( -150, -150, 300, 300 );
            bg.graphics.endFill();
            
            area = new Sprite();
            area.graphics.clear();
            area.graphics.beginFill( 0x000000, 0.6 );
            area.graphics.drawCircle( 0, 0, 120 );
            area.graphics.drawCircle( 0, 0, 100 );
            area.graphics.endFill();
            
            centerPoint = new Sprite();
            centerPoint.graphics.clear();
            centerPoint.graphics.beginFill( 0xffcc00, 1.0 );
            centerPoint.graphics.drawRect( -2, -2, 4, 4 );
            centerPoint.graphics.endFill();
            
            //default
            _colorize( area, 0xffffff );
            
            //UI stack
            addChild( bg );
            addChild( area );
            
            addChild( centerPoint );
            _drawMarkings();
        }
        
        public function main():void
        {
            //UI
            _draw();
            
            //events
            stage.addEventListener( Event.RESIZE, onResize );
            
            //action
            onResize();
        }
        
        private var _UIdots:Dictionary = new Dictionary();
        
        public function addClientDot( name:String, client:NetworkClient ):void
        {
            if( !_UIdots[ name ] )
            {
                _UIdots[ name ] = new UIClientDot( client, this );
                addChild( _UIdots[ name ] );
                _UIdots[ name ].alignOnRing();
            }
        }
        
        public function removeClientDot( name:String ):void
        {
            if( _UIdots[ name ] )
            {
                removeChild( _UIdots[ name ] );
                delete _UIdots[ name ];
            }
        }
        
        public function updateClientDot( name:String, client:NetworkClient ):void
        {
            if( _UIdots[ name ] )
            {
                _UIdots[ name ].update( client );
            }
        }
        
        public function removeAllClientDot():void
        {
            var entry:String;
            
            for( entry in _UIdots )
            {
                if( contains( _UIdots[ entry ] ) )
                {
                    removeClientDot( entry );
                }
            }
        }
    }
}