/*
Version: MPL 1.1/GPL 2.0/LGPL 2.1

The contents of this file are subject to the Mozilla Public License Version
1.1 (the "License"); you may not use this file except in compliance with
the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
for the specific language governing rights and limitations under the
License.

The Original Code is [circulate library].

The Initial Developers of the Original Code are
Zwetan Kjukov <zwetan@gmail.com> and Marc Alcaraz <ekameleon@gmail.com>.
Portions created by the Initial Developers are Copyright (C) 2013
the Initial Developers. All Rights Reserved.

Contributor(s):

Alternatively, the contents of this file may be used under the terms of
either the GNU General Public License Version 2 or later (the "GPL"), or
the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
in which case the provisions of the GPL or the LGPL are applicable instead
of those above. If you wish to allow use of your version of this file only
under the terms of either the GPL or the LGPL, and not to allow others to
use your version of this file under the terms of the MPL, indicate your
decision by deleting the provisions above and replace them with the notice
and other provisions required by the LGPL or the GPL. If you do not delete
the provisions above, a recipient may use your version of this file under
the terms of any one of the MPL, the GPL or the LGPL.
*/

package
{
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.geom.ColorTransform;
    
    import library.circulate.Network;
    import library.circulate.NetworkConfiguration;
    import library.circulate.NetworkType;
    import library.circulate.events.NetworkEvent;
    import library.circulate.utils.getLocalUserName;
    import library.circulate.utils.traceNetworkInterfaces;

    [ExcludeClass]
    [SWF(width="800", height="600", frameRate="24", backgroundColor="#ffcc00")]
    public class circulate_test extends Sprite
    {
        
        
        public var config:NetworkConfiguration;
        public var localAreaNetwork:Network;
        
        //UI
        public var connectionDot:Sprite; 
        
        public function circulate_test()
        {
            _buildConnectionUI();
            addChild( connectionDot);
            connectionDot.x = stage.stageWidth - ( connectionDot.width + 5 );
            connectionDot.y = ( connectionDot.height + 10 );
            _colorize( connectionDot, 0xcccccc );
            
            
            /* You have 2 ways to create your config
               
               either you directly pass into the ctor your own literal object
               butbe carefull if you don't declare some properties the y will be null/empty
            */
            config = new NetworkConfiguration( { username: getLocalUserName() } );
            
            /* or you first use the defautl config
               and override accordingly
               
               this guarantee to have all the properties needed
            */
            config = Network.getDefaultConfiguration();
            
            //override
            config.username = "test" + _randomRange( 0, 1000 );
            //config.connectionTimeout = 5 * 1000;
            
            //configure
            //config.serverKey = "503a63139c4a687fc822004e-7d1c016995c5";
            
            localAreaNetwork = new Network( NetworkType.local, config );
            //localAreaNetwork = new Network();
            
            trace( "username: " + localAreaNetwork.config.username );
            
            localAreaNetwork.addEventListener( NetworkEvent.CONNECTED, onNetworkConnect );
            localAreaNetwork.addEventListener( NetworkEvent.DISCONNECTED, onNetworkDisconnect );
            
            //localAreaNetwork.connect();
            //localAreaNetwork.connect( config.localArea );
            //localAreaNetwork.connect( config.testServer );
            //localAreaNetwork.connect( config.adobeServer, "503a63139c4a687fc822004e-7d1c016995c5" );
            //localAreaNetwork.connect( config.adobeServer );
            
            localAreaNetwork.connect();
            //localAreaNetwork.createNode( "test" );
            
        }
        
        private function _randomRange( minNum:Number, maxNum:Number ):Number   
        {  
            return ( Math.floor(Math.random() * (maxNum - minNum + 1)) + minNum );  
        }
        
        private function _buildConnectionUI():void
        {
            connectionDot = new Sprite();
            connectionDot.graphics.clear();
            connectionDot.graphics.beginFill( 0x000000, 1.0 );
            connectionDot.graphics.drawRoundRect( 0, 0, 16, 16, 16, 16 );
            connectionDot.graphics.endFill();
            
        }
        
        private function _colorize( target:DisplayObject, color:uint ):void
        {
            var ct:ColorTransform = new ColorTransform();
                ct.color = color;
            
            target.transform.colorTransform = ct;
        }
        
        
        public function onNetworkConnect( event:NetworkEvent ):void
        {
            trace( "test connected" );
            _colorize( connectionDot, 0x00ff00 );
        }
        
        public function onNetworkDisconnect( event:NetworkEvent ):void
        {
            trace( "test disconnected" );
            _colorize( connectionDot, 0xff0000 );
        }
        
    }
}