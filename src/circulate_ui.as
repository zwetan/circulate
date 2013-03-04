package
{
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.UncaughtErrorEvent;
    import flash.geom.ColorTransform;
    import flash.text.AntiAliasType;
    import flash.text.TextField;
    import flash.text.TextFieldType;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    import flash.ui.Keyboard;
    
    [ExcludeClass]
    [SWF(width="800", height="600", frameRate="24", backgroundColor="#ffcc00")]
    public class circulate_ui extends Sprite
    {
        //UI
        public var topbar:Sprite;
        public var title:TextField;
        public var undertitle:TextField;
        public var connectionDot:Sprite;
        
        public var bgoutput:TextField;
        public var output:TextField;
        public var input:TextField;
        
        public function circulate_ui()
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
        
        public function onGlobalError( event:UncaughtErrorEvent = null ):void
        {
            var message:String = "";
            
            if( event && event.error )
            {
            
                if( event.error.message )
                {
                    message = event.error.message;
                }
                else if( event.error.text )
                {
                    message = event.error.text;
                }
                else
                {
                    message = event.error.toString();
                }
            
            }
            else
            {
                message = "unknown";
            }
            
            var msg:String =  "## Global Error " + message + " ##";
            trace( msg );
        }
        
        private function onAddedToStage( event:Event = null ):void
        {
            trace( "ApplicationBootstrap.onAddedToStage()" );
            removeEventListener( Event.ADDED_TO_STAGE, onAddedToStage );
            main();
        }
        
        private function onResize( event:Event = null ):void
        {
            topbar.width = stage.stageWidth;
            title.width  = stage.stageWidth - ( connectionDot.width + 10 );
            title.height = 20;
            undertitle.y = title.y + title.height;
            undertitle.width  = stage.stageWidth;
            undertitle.height = 20;
            connectionDot.x = stage.stageWidth - ( connectionDot.width + 5 );
            connectionDot.y = ( 2 );

            bgoutput.width  = stage.stageWidth - 1;
            bgoutput.height = stage.stageHeight - ( 40 ) - 20 - 1;
            bgoutput.y      =  undertitle.y + undertitle.height;
            
            output.width  = stage.stageWidth - 1;
            output.height = stage.stageHeight - ( 40 ) - 20 - 1;
            output.y      =  undertitle.y + undertitle.height;
            
            input.width   = stage.stageWidth - 1;
            input.height  = 20;
            input.y       = output.y + output.height;
        }
        
       private function onKeyDown( event:KeyboardEvent ):void
        {
            var code:uint = event.charCode;
            var line:String = "";
            //trace( "code = " + code );
            
            switch( code )
            {
                case Keyboard.ENTER:
                line = input.text;
                //trace( "ENTER" );
                //trace( "input = [" + command + "]" );
                input.text = "";
                _interpret( line );
                break;
            }
        }
        
        private function _draw():void
        {
            topbar = new Sprite();
            topbar.graphics.clear();
            topbar.graphics.beginFill( 0x000000, 1.0 );
            topbar.graphics.drawRect( 0, 0, 200, 20 );
            topbar.graphics.endFill();
            
            title = new TextField();
//            title.border = true;
//            title.borderColor = 0xff0000;
            title.multiline = false;
            title.selectable = false;
            title.defaultTextFormat = new TextFormat( "Arial", 14, 0xffffff, true );
            
            undertitle = new TextField();
//            undertitle.border = true;
//            undertitle.borderColor = 0xff0000;
            undertitle.multiline = false;
            undertitle.selectable = false;
            undertitle.defaultTextFormat = new TextFormat( "Arial", 10, 0x000000, true );
            
            connectionDot = new Sprite();
            connectionDot.graphics.clear();
            connectionDot.graphics.beginFill( 0x000000, 1.0 );
            connectionDot.graphics.drawRoundRect( 0, 0, 16, 16, 16, 16 );
            connectionDot.graphics.endFill();

            bgoutput = new TextField();
            bgoutput.border = true;
            bgoutput.borderColor = 0x0000ff;
            bgoutput.multiline = true;
            bgoutput.selectable = false;
            bgoutput.wordWrap = true;
            bgoutput.defaultTextFormat = new TextFormat( "Arial", 10, 0x555555, true, null, null, null, null, TextFormatAlign.RIGHT );
            
            output = new TextField();
            output.border = true;
            output.borderColor = 0xff0000;
            output.multiline = true;
            output.selectable = false;
            output.wordWrap = true;
            output.defaultTextFormat = new TextFormat( "Arial", 10, 0x555555, true );
            
            input = new TextField();
            input.border = true;
            input.borderColor = 0xff00ff;
            input.type = TextFieldType.INPUT;
            input.multiline = false;
            input.wordWrap = false;
            input.antiAliasType = AntiAliasType.ADVANCED;
            input.defaultTextFormat = new TextFormat( "Arial", 10, 0x000000, true );
            
            //default
            _colorize( connectionDot, 0xcccccc );
            title.text = "unknown";
            undertitle.text = "000000";
            
            //UI stack
            addChild( topbar );
            addChild( title );
            addChild( undertitle );
            addChild( connectionDot );
            addChild( bgoutput );
            addChild( output );
            addChild( input );
        }
        
        protected function _interpret( line:String ):void
        {
            
        }
        
        public function main():void
        {
            //config
            stage.align     = StageAlign.TOP_LEFT;
            stage.scaleMode = StageScaleMode.NO_SCALE;
            
            //UI
            _draw();
            
            //events
            stage.addEventListener( Event.RESIZE, onResize );
            stage.addEventListener( KeyboardEvent.KEY_DOWN, onKeyDown );
            
            //action
            onResize();
            
            writeline( "hello world" );
            writelineToBackground( "test" );
        }
        
        private function _colorize( target:DisplayObject, color:uint ):void
        {
            var ct:ColorTransform = new ColorTransform();
                ct.color = color;
            
            target.transform.colorTransform = ct;
        }
        
        public function updateConnection( color:uint ):void
        {
            _colorize( connectionDot, color );
        }
        
        public function updateUsername( name:String ):void
        {
            title.text = name;
        }
        
        public function updatePeerID( peerID:String ):void
        {
            undertitle.text = peerID;
        }
        
        public function clearConsole():void
        {
            output.text = "";
        }
        
        public function writeline( message:String ):void
        {
            output.appendText( message + "\n" );
            output.scrollV = output.numLines;
        }
        
        public function clearBackground():void
        {
            bgoutput.text = "";
        }
        
        public function writelineToBackground( message:String ):void
        {
            bgoutput.appendText( message + "\n" );
        }
    }
}