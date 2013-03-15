package
{
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.geom.ColorTransform;
    import flash.geom.Point;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    
    import library.circulate.RingTopology;
    import library.circulate.NetworkClient;
    import library.circulate.RingSpan;
    
    public class UIClientDot extends Sprite
    {
        private var _client:NetworkClient;
        private var _container:DisplayObject;
        
        public var bgarea:Sprite;
        public var bgcircle:Sprite;
        public var circleborder:Sprite;
        public var dotname:TextField;
        
        public var centerPoint:Sprite;
    
        public function UIClientDot( client:NetworkClient, container:DisplayObject )
        {
            super();
            
            _client = client;
            _container = container;
            
            if( stage )
            {
                onAddedToStage();
            }
            else
            {
                addEventListener( Event.ADDED_TO_STAGE, onAddedToStage );
            }
        }
        
        private function onAddedToStage( event:Event = null ):void
        {
            removeEventListener( Event.ADDED_TO_STAGE, onAddedToStage );
            main();
        }
        
        private function onResize( event:Event = null ):void
        {
//            bgcircle.x = (bgarea.x + bgarea.width)/2;
//            bgcircle.y = (bgarea.y + bgarea.height)/2;
            
//            dotname.x = (bgarea.x + bgarea.width)/2 - dotname.width;
//            dotname.y = (bgarea.y + bgarea.height)/2 - dotname.height;
              
              //dotname.x = bgarea.width/2 - dotname.width/2;
              //dotname.y = bgarea.height/2 - dotname.height/2;
              
//              dotname.x = bgarea.x + bgarea.width + 2;
//              dotname.y = bgarea.height/2 - dotname.height/2;

            //alignOnRing( _container );
        }
        
        private function _draw():void
        {
            var rndcolor:uint = _randomColor();
            
            bgarea = new Sprite();
            bgarea.graphics.clear();
            bgarea.graphics.beginFill( 0x000000, 0.4 );
            bgarea.graphics.drawRect( -10, -10, 20, 20 );
            bgarea.graphics.endFill();
            
            circleborder = new Sprite();
            circleborder.graphics.clear();
            circleborder.graphics.lineStyle( 4, 0xffffff );
            circleborder.graphics.drawCircle( 0, 0, 10 );
            circleborder.graphics.endFill();
            
            bgcircle = new Sprite();
            bgcircle.graphics.clear();
            bgcircle.graphics.beginFill( rndcolor, 1.0 );
            bgcircle.graphics.drawCircle( 0, 0, 10 );
            //bgcircle.graphics.drawCircle( 20, 20, 10 );
            bgcircle.graphics.endFill();
            
            dotname = new TextField();
//            dotname.border = true;
//            dotname.borderColor = 0xff0000;
            dotname.multiline = false;
            dotname.selectable = false;
            dotname.autoSize = TextFieldAutoSize.CENTER;
            dotname.defaultTextFormat = new TextFormat( "Arial", 8, 0x000000, true );
            
            centerPoint = new Sprite();
            centerPoint.graphics.clear();
            centerPoint.graphics.beginFill( 0xffcc00, 1.0 );
            centerPoint.graphics.drawRect( -2, -2, 4, 4 );
            centerPoint.graphics.endFill();
            
            if( _client && (_client.username != "") )
            {
                dotname.text = _client.username;
            }
            else
            {
                dotname.text = "unknown";
            }
            
            _colorize( circleborder, 0x000000 );
            
            //addChild( bgarea );
            addChild( circleborder );
            addChild( bgcircle );
            
            //addChild( dotname );
            
            addChild( centerPoint );
        }
        
        public function main():void
        {
            //config
            
            //UI
            _draw();
            
            //events
            stage.addEventListener( Event.RESIZE, onResize );
            
            //action
            onResize();
            
        }
        
        public function get client():NetworkClient { return _client; }
        
        private function _randomColor():uint
        {
            //var R:uint = _randomRange( 0, 255 );
            var R:uint = 128;
            var G:uint = _randomRange( 0, 255 );
            //var B:uint = _randomRange( 0, 255 );
            var B:uint = 255;
            
            return (R << 16) | (G << 8) | B;
        }
        
        private function _randomRange( minNum:Number, maxNum:Number ):Number   
        {  
            return ( Math.floor(Math.random() * (maxNum - minNum + 1)) + minNum );  
        }
        
        private function _colorize( target:DisplayObject, color:uint ):void
        {
            var ct:ColorTransform = new ColorTransform();
                ct.color = color;
            
            target.transform.colorTransform = ct;
        }
        
        public function update( client:NetworkClient ):void
        {
            _client = client;
            dotname.text = _client.username;
            
            if( _client.elected )
            {
                _colorize( circleborder, 0xffffff );
            }
            else
            {
                _colorize( circleborder, 0x000000 );
            }
            
        }
        
        public function alignOnRing():void
        {
            var address:String = _client.peerID;
            var distance:uint  = 120; //from center of ring
            var position:int   = 0; //align center of span
            var correctAngle:Boolean = true; //to slightly alterate the pos of the circle so for the same address span the 2 circle does not cover each other
            var correctDistance:Boolean = true;
            var translatePoint:Point = RingTopology.getCirclePosition( address, distance, position, correctAngle, correctDistance );
            this.x = translatePoint.x;
            this.y = translatePoint.y;            
        }
        
        
        public function removeSelf():void
        {
            _client = null;
            _container = null;
            
        }
        
    }
}