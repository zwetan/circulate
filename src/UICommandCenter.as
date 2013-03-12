package
{
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.geom.ColorTransform;
    import flash.geom.Point;
    
    import library.circulate.AutomaticDistributedElection;
    import library.circulate.NetworkClient;
    import library.circulate.RingSpan;
    
    public class UICommandCenter extends Sprite
    {
        //UI
        public var bg:Sprite;
        public var area:Sprite;
        
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
            x = (stage.stageWidth - width)/2;
            y = (stage.stageHeight - height)/2;
        }
        
        private function _colorize( target:DisplayObject, color:uint ):void
        {
            var ct:ColorTransform = new ColorTransform();
                ct.color = color;
            
            target.transform.colorTransform = ct;
        }
        
        private function _draw():void
        {
            bg = new Sprite();
            bg.graphics.clear();
            bg.graphics.beginFill( 0x000000, 0.2 );
            bg.graphics.drawRect( 0, 0, 240, 240 );
            bg.graphics.endFill();
            
            area = new Sprite();
            area.graphics.clear();
            area.graphics.beginFill( 0x000000, 0.6 );
            area.graphics.drawCircle( 120, 120, 120 );
            area.graphics.drawCircle( 120, 120, 80 );
            area.graphics.endFill();
            
            //default
            _colorize( area, 0xff00cc );
            
            //UI stack
            addChild( bg );
            addChild( area );
            
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
        
    }
}