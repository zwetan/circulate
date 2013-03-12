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
    
    import library.circulate.AutomaticDistributedElection;
    import library.circulate.NetworkClient;
    import library.circulate.RingSpan;
    
    public class UIClientDot extends Sprite
    {
        private var _client:NetworkClient;
        
        public var bgarea:Sprite;
        public var bgcircle:Sprite;
        public var circleborder:Sprite;
        public var dotname:TextField;
    
        public function UIClientDot( client:NetworkClient )
        {
            super();
            
            _client = client;
            
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
              
              dotname.x = bgarea.width/2 - dotname.width/2;
              dotname.y = bgarea.height/2 - dotname.height/2;
        }
        
        private function _draw():void
        {
            var rndcolor:uint = _randomColor();
            
            bgarea = new Sprite();
            bgarea.graphics.clear();
            bgarea.graphics.beginFill( 0x000000, 0.0 );
            bgarea.graphics.drawRect( 0, 0, 40, 40 );
            bgarea.graphics.endFill();
            
            circleborder = new Sprite();
            circleborder.graphics.clear();
            circleborder.graphics.lineStyle( 4, 0xffffff );
            circleborder.graphics.drawCircle( 20, 20, 20 );
            circleborder.graphics.endFill();
            
            bgcircle = new Sprite();
            bgcircle.graphics.clear();
            bgcircle.graphics.beginFill( rndcolor, 1.0 );
            bgcircle.graphics.drawCircle( 20, 20, 20 );
            bgcircle.graphics.drawCircle( 20, 20, 10 );
            bgcircle.graphics.endFill();
            
            dotname = new TextField();
//            dotname.border = true;
//            dotname.borderColor = 0xff0000;
            dotname.multiline = false;
            dotname.selectable = false;
            dotname.autoSize = TextFieldAutoSize.CENTER;
            dotname.defaultTextFormat = new TextFormat( "Arial", 8, 0x000000, true );
            dotname.text = _client.username;
            
            addChild( bgarea );
            addChild( circleborder );
            addChild( bgcircle );
            
            addChild( dotname );
        }
        
        public function main():void
        {
            //config
            
            //UI
            _draw();
            
            //events
            stage.addEventListener( Event.RESIZE, onResize );
            circleborder.visible = false;
            
            //action
            onResize();
            
        }
        
        public function get client():NetworkClient { return _client; }
        
        private function _randomColor():uint
        {
            var R:uint = _randomRange( 0, 255 );
            var G:uint = _randomRange( 0, 255 );
            var B:uint = _randomRange( 0, 255 );
            
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
            circleborder.visible = _client.elected;
        }
        
        public function alignOnRing( target:DisplayObject, ringspan:String ):void
        {
            var spanAsAngle:uint = 135 + RingSpan.getAngle( ringspan );
            var cangle:int = AutomaticDistributedElection.getRingSpanCorrectionAngle( ringspan );
            spanAsAngle += cangle * 10;
            var distance:Number = 100;
            var angle:Number = (2 * Math.PI) * (spanAsAngle / 180);
            var translatePoint:Point = Point.polar( distance, angle );
            this.x = translatePoint.x + (target.x + (target.width/2)) - (this.width/2);
            this.y = translatePoint.y + (target.y + (target.height/2)) - (this.height/2);
        }
        
    }
}