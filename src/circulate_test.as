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
    import core.strings.startsWith;
    
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.geom.ColorTransform;
    import flash.utils.setTimeout;
    
    import library.circulate.Network;
    import library.circulate.NetworkClient;
    import library.circulate.NetworkCommand;
    import library.circulate.NetworkConfiguration;
    import library.circulate.NetworkNode;
    import library.circulate.NetworkType;
    import library.circulate.commands.ChatMessage;
    import library.circulate.events.NetworkEvent;
    import library.circulate.utils.getLocalUserName;
    import library.circulate.utils.traceNetworkInterfaces;

    [ExcludeClass]
    [SWF(width="800", height="400", frameRate="24", backgroundColor="#ffcc00")]
    public class circulate_test extends circulate_ui
    {
        
        
        public var config:NetworkConfiguration;
        public var localAreaNetwork:Network;
        
        public function circulate_test()
        {
            
        }
        
        private function _randomRange( minNum:Number, maxNum:Number ):Number   
        {  
            return ( Math.floor(Math.random() * (maxNum - minNum + 1)) + minNum );  
        }
        
        protected override function _interpret( line:String ):void
        {
            var command:NetworkCommand;
            var cmd:String = "";
            var c:String = "";
            var i:uint   = 0;
            
//            trace( "line starts with \\ = " + (startsWith( line, "\\" )) );
            
            //is it a command ?
            if( startsWith( line, "\\" ) )
            {
                line = line.substr( 1 );
//                trace( "1-line = [" + line + "]" );
                c = line.charAt( i );
                
                while( c != " " )
                {
                    c = line.charAt( i++ );
//                    trace( "c=" + c );
                    if( line.length == i-1 )
                    {
                        break;
                    }
                }
                
                cmd  = line.substr( 0, i-1 );
                line = line.substr( i );
//                trace( "cmd = [" + cmd + "]" );
//                trace( "line = [" + line + "]" );
                interpret( cmd, line );
            }
            else
            {
//                trace( "chat = [" + line + "]" );
                interpret( "chat", line );
            }
        }
        
        public function interpret( command:String, line:String ):void
        {
            var username:String = localAreaNetwork.client.username;
            var netcmd:NetworkCommand;
            var sendcmd:Boolean = true;
            
            switch( command )
            {
                case "test":
                writeline( "## user [" + username + "] is testing \"" + line + "\"" );
                sendcmd = false;
                break;
                
                case "node":
                localAreaNetwork.createNode( line );
                break;
                
                case "nodechat":
                var nodename:String;
                var lines:Array = line.split( " " );
                nodename = lines.shift();
                line = lines.join( " " );
                netcmd = new ChatMessage( line, localAreaNetwork.client.peerID, nodename );
                break;
                
                case "chat":
                netcmd = new ChatMessage( line, localAreaNetwork.client.peerID );
                break;
                
                case "clear":
                clearConsole();
                break;
                
                default:
                writeline( "## command \"" + command + "\" can not be interpreted" );
                sendcmd = false;
            }
            
            if( sendcmd && netcmd)
            {
                localAreaNetwork.sendCommandToNode( netcmd );
            }
            
        }
        
        
        public override function main():void
        {
            super.main();
            
            afterCircleRelease = sendCustomCommand;
            TestCustomCommand.reference = circle;
            
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
            //config.loopback = false;
            
            //configure
            //config.serverKey = "503a63139c4a687fc822004e-7d1c016995c5";
            
            localAreaNetwork = new Network( NetworkType.local, config );
            localAreaNetwork.writer = writeline;
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
//            var sec:uint = _randomRange( 0, 30 );
//            var dolater0:uint = setTimeout( function():void { localAreaNetwork.connect(); }, (sec*1000) );
        }
        
        private function onLoop( event:Event ):void
        {
            clearBackground();
            
            var i:uint;
            var j:uint;
            var node:NetworkNode;
            var client:NetworkClient;
            var post:String = "";
            var elect:String = "(elected) ";
            
            writelineToBackground( "nodes:" );
            writelineToBackground( "------" );
            for( i=0; i<localAreaNetwork.nodes.length; i++ )
            {
                node = localAreaNetwork.nodes[i];
                writelineToBackground( (node.isElected ? elect: "") + node.name );
                writelineToBackground( node.group.neighborCount  + " :neighbours _| " );
                writelineToBackground( node.estimatedMemberCount + "    :members _| " );
                writelineToBackground( node.clients.length       + "    :clients _| " );
                for( j=0; j<node.clients.length; j++ )
                {
                    client = node.clients[ j ];
                    if( client == localAreaNetwork.client )
                    {
                        post = "(me) ";
                    }
                    else
                    {
                        post = "";
                    }
                    
                    writelineToBackground( post + "["+j+"]: " + client.username );
                }
            }
            
            writelineToBackground( "" );
            
        }
        
        
        public function onNetworkConnect( event:NetworkEvent ):void
        {
            trace( "test connected" );
            updateUsername( localAreaNetwork.client.username );
            updatePeerID( localAreaNetwork.client.peerID );
            updateConnection( 0x00ff00 );
            
            //var dolater1:uint = setTimeout( function():void { localAreaNetwork.createNode( "test" ); }, 10000 ); 
            
            addEventListener( Event.ENTER_FRAME, onLoop );
        }
        
        public function onNetworkDisconnect( event:NetworkEvent ):void
        {
            trace( "test disconnected" );
            updateConnection( 0xff0000 );
            removeEventListener( Event.ENTER_FRAME, onLoop );
        }
        
        public function sendCustomCommand():void
        {
            var localPeerID:String = localAreaNetwork.client.peerID;
            var custom:TestCustomCommand = new TestCustomCommand( localPeerID, circle.x, circle.y );
            localAreaNetwork.sendCommandToNode( custom );
        }
        
    }
}