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
    import flash.media.Camera;
    import flash.media.Video;
    import flash.utils.Dictionary;
    import flash.utils.setTimeout;
    
    import library.circulate.RingTopology;
    import library.circulate.NetworkClient;
    import library.circulate.NetworkCommand;
    import library.circulate.NetworkConfiguration;
    import library.circulate.NetworkNode;
    import library.circulate.NetworkSystem;
    import library.circulate.NetworkType;
    import library.circulate.NodeType;
    import library.circulate.commands.ChatMessage;
    import library.circulate.commands.ClientList;
    import library.circulate.commands.RequestInformation;
    import library.circulate.events.ClientEvent;
    import library.circulate.events.NeighborEvent;
    import library.circulate.events.NetworkEvent;
    import library.circulate.networks.LocalAreaNetwork;
    import library.circulate.networks.Network;
    import library.circulate.nodes.Node;
    import library.circulate.utils.getLocalUserName;
    import library.circulate.utils.traceNetworkInterfaces;

    [ExcludeClass]
    [SWF(width="800", height="400", frameRate="24", backgroundColor="#ffcc00")]
    public class circulate_test extends circulate_ui
    {
        
        
        public var config:NetworkConfiguration;
        public var localAreaNetwork:NetworkSystem;
        
        public var videotile:Video;
        
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
            var netsys:NetworkSystem = localAreaNetwork; //choose network here
            
            //user info
            var username:String = netsys.client.username;
            var peerID:String   = netsys.client.peerID;
            
            var netcmd:NetworkCommand = null;
            var netnode:NetworkNode   = null;
            var sendcmd:Boolean       = true;
            
            var nodename:String;
            var lines:Array;
            
            switch( command )
            {
                //example: \start
                case "start":
                netsys.connect();
                sendcmd = false;
                break;
                
                //example: \stop
                case "stop":
                netsys.disconnect();
                sendcmd = false;
                break;
                
                //example: \destroy
                case "destroy":
                netsys.destroy();
                sendcmd = false;
                break;
                
                //example: \test
                case "test":
                writeline( "## user [" + username + "] is testing \"" + line + "\"" );
                sendcmd = false;
                break;
                
                //example: \publish
                case "publish":
                videotile = new Video();
                addChild( videotile );
                netnode = netsys.createNode( "mycamera", NodeType.stream );
                
                var cam:Camera = Camera.getCamera();
                    cam.setQuality( 0, 100 );
	            videotile.attachCamera( cam );
	            netnode.stream.attachCamera( cam );
                
                netnode.stream.videoReliable = true;
                netnode.stream.multicastAvailabilitySendToAll = true;
                netnode.stream.multicastAvailabilityUpdatePeriod = 0;
                netnode.stream.multicastFetchPeriod = 0;
                netnode.stream.multicastPushNeighborLimit = 16;
                netnode.stream.multicastRelayMarginDuration = 10;
                netnode.stream.multicastWindowDuration = 10;
	            
                if( netnode.stream.videoStreamSettings )
                {
                    netnode.stream.videoStreamSettings.setQuality( 0, 100 );
                }
                
	            netnode.stream.publish( "multicast" );
                break;
                
                //example: \subscribe
                case "subscribe":
                videotile = new Video();
                addChild( videotile );
                netnode = netsys.createNode( "mycamera", NodeType.stream );
                
                netnode.stream.videoReliable = true;
                netnode.stream.multicastAvailabilitySendToAll = true;
                netnode.stream.multicastAvailabilityUpdatePeriod = 0;
                netnode.stream.multicastFetchPeriod = 0;
                netnode.stream.multicastPushNeighborLimit = 16;
                netnode.stream.multicastRelayMarginDuration = 10;
                netnode.stream.multicastWindowDuration = 10;
                
	            videotile.attachNetStream( netnode.stream );
                netnode.stream.play( "multicast" );
                break;
                
                //example: \node name
                case "node":
                lines    = line.split( " " );
                nodename = lines.shift();
                line     = lines.join( " " );
                
                netsys.createNode( nodename );
                break;
                
                //example: \nodeleave name
                case "nodeleave":
                lines    = line.split( " " );
                nodename = lines.shift();
                line     = lines.join( " " );
                
                netsys.leaveNode( nodename );
                break;
                
                //example: \nodejoin name
                case "nodejoin":
                lines    = line.split( " " );
                nodename = lines.shift();
                line     = lines.join( " " );
                
                if( nodename != "" )
                {
                    netsys.joinNode( nodename );
                }
                else
                {
                    writeline( "# can't joine node, you need to provide a name." );
                }
                break;
                
                //example: \nodechat test hello world
                case "nodechat":
                lines    = line.split( " " );
                nodename = lines.shift();
                line     = lines.join( " " );
                
                netcmd  = new ChatMessage( line, peerID, nodename );
                netnode = netsys.findNode( nodename );
                sendcmd = true;
                break;
                
                case "chat":
                netcmd  = new ChatMessage( line, peerID );
                netnode = netsys.commandCenter;
                sendcmd = true;
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
                netsys.sendCommandToNode( netcmd, netnode );
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
            config.loopback = false;
            
            //configure
            //config.serverKey = "503a63139c4a687fc822004e-7d1c016995c5";
            
            //localAreaNetwork = new Network( NetworkType.local, config );
            localAreaNetwork = new LocalAreaNetwork( config );
            localAreaNetwork.writer = writeline;
            //localAreaNetwork = new Network();
            
            trace( "username: " + localAreaNetwork.config.username );
            
            localAreaNetwork.addEventListener( NetworkEvent.CONNECTED, onNetworkConnect );
            localAreaNetwork.addEventListener( NetworkEvent.DISCONNECTED, onNetworkDisconnect );
            localAreaNetwork.addEventListener( NetworkEvent.COMMANDCENTER_READY, onNetworkCommandCenterReady );
            
            //localAreaNetwork.connect();
            //localAreaNetwork.connect( config.localArea );
            //localAreaNetwork.connect( config.testServer );
            //localAreaNetwork.connect( config.adobeServer, "503a63139c4a687fc822004e-7d1c016995c5" );
            //localAreaNetwork.connect( config.adobeServer );
            
            localAreaNetwork.connect();
//            var sec:uint = _randomRange( 0, 30 );
//            var dolater0:uint = setTimeout( function():void { localAreaNetwork.connect(); }, (sec*1000) );


            var netsys:NetworkSystem = localAreaNetwork;
                //netsys.
            
            var cmd:ClientList = new ClientList();
        }
        
        public var commandcenter:UICommandCenter;
        
        private var _loopcount:uint = 0;
        private var _loopmax:uint   = 10;
        
        private var _indexDot:uint = 0;
        private var _UIdots:Dictionary = new Dictionary();
        
//        public function removeClientCircle( client:NetworkClient ):void
//        {
//            var peerID:String = client.peerID;
//            removeChild( _UIdots[ peerID ] );
//        }
        
        private function onLoop( event:Event = null ):void
        {
            var netsys:NetworkSystem = localAreaNetwork;
            var node:NetworkNode;
            var client:NetworkClient;
            
            var i:uint;
            var j:uint;
            
            clearBackground();
            writelineToBackground( "estimatedTotalMember = " + netsys.estimatedTotalMember );
            writelineToBackground( "    knownTotalMember = " + netsys.knownTotalMember );
            
            for( i=0; i<netsys.nodes.length; i++ )
            {
                node = netsys.nodes[ i ];
                writelineToBackground( node.name + "    " );
                
                for( j=0; j<node.clients.length; j++ )
                {
                    client = node.clients[ j ];
                    writelineToBackground( " |__[" + j + "] : " + client.username );
                }
                
            }
        }
        
        public function onNetworkConnect( event:NetworkEvent ):void
        {
            writeline( "onNetworkConnect()" );
            
            updateUsername( localAreaNetwork.client.username );
            updatePeerID( localAreaNetwork.client.peerID );
            updateConnection( 0x00ff00 );
            
            //var dolater1:uint = setTimeout( function():void { localAreaNetwork.createNode( "test" ); }, 10000 ); 
            
            //addEventListener( Event.ENTER_FRAME, onLoop );
        }
        
        public function onNetworkDisconnect( event:NetworkEvent ):void
        {
            writeline( "onNetworkDisconnect()" );
            
            updateConnection( 0xff0000 );
            //removeEventListener( Event.ENTER_FRAME, onLoop );
            clearBackground();
            
            commandcenter.removeAllClientDot();
            
            if( contains( commandcenter ) )
            {
                removeChild( commandcenter );
            }
            
        }
        
        public function onNetworkCommandCenterReady( event:NetworkEvent ):void
        {
            writeline( "onNetworkCommandCenterReady()" );
            
            if( !commandcenter )
            {
                commandcenter = new UICommandCenter();
            }
            
            if( !contains( commandcenter ) )
            {
                addChild( commandcenter );
            }
            
            
            localAreaNetwork.commandCenter.addEventListener( ClientEvent.CONNECTED, onClientConnect );
            localAreaNetwork.commandCenter.addEventListener( ClientEvent.ADDED, onClientConnect );
            localAreaNetwork.commandCenter.addEventListener( ClientEvent.REMOVED, onClientDisconnect );
            localAreaNetwork.commandCenter.addEventListener( ClientEvent.UPDATED, onClientUpdate );
            localAreaNetwork.commandCenter.addEventListener( NeighborEvent.CONNECT, onNeighborConnect );
            localAreaNetwork.commandCenter.addEventListener( NeighborEvent.DISCONNECT, onNeighborDisconnect );
            
            trace( "my client: " + localAreaNetwork.client.peerID );
            onLoop();
        }
        
        private function onNeighborConnect( event:NeighborEvent ):void
        {
            writeline( "onNeighborConnect()" );
            
            var client:NetworkClient = event.client;
            commandcenter.addClientDot( client.peerID, client );
            onLoop();
        }
        
        private function onNeighborDisconnect( event:NeighborEvent ):void
        {
            writeline( "onNeighborDisconnect()" );
            
            var client:NetworkClient = event.client;
            commandcenter.removeClientDot( client.peerID );
            onLoop();
        }
        
        private function onClientConnect( event:ClientEvent ):void
        {
            writeline( "onClientConnect()" );
            
            var client:NetworkClient = event.client;
            commandcenter.addClientDot( client.peerID, client );
        }
        
        private function onClientDisconnect( event:ClientEvent ):void
        {
            writeline( "onClientDisconnect()" );
            
            var client:NetworkClient = event.client;
            commandcenter.removeClientDot( client.peerID );
        }
        
        private function onClientUpdate( event:ClientEvent ):void
        {
            writeline( "onClientUpdate()" );
            
            var client:NetworkClient = event.client;
            commandcenter.updateClientDot( client.peerID, client );
        }
        
        public function sendCustomCommand():void
        {
            var localPeerID:String = localAreaNetwork.client.peerID;
            var custom:TestCustomCommand = new TestCustomCommand( localPeerID, circle.x, circle.y );
            localAreaNetwork.sendCommandToNode( custom );
        }
        
    }
}