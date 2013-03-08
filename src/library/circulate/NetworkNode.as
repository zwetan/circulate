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

package library.circulate
{
    import flash.net.GroupSpecifier;
    import flash.net.NetGroup;
    import flash.utils.Dictionary;

    /**
     * 
     */
    public interface NetworkNode
    {
        function get type():NodeType;
        function get name():String;
        function get specificier():GroupSpecifier;
        function get group():NetGroup;
        function get joined():Boolean;
        function get isElected():Boolean;
        function get isFullMesh():Boolean;
        
        function get clients():Vector.<NetworkClient>;
        function get estimatedMemberCount():uint;
        
        function findClientByPeerID( peerID:String ):NetworkClient;
        function addLocalClient():void;
        function removeLocalClient():void;
        
        function join( password:String = "" ):void;
        function leave():void;
        
//        function post( command:NetworkCommand ):String;
//        function sendToAllNeighbors( command:NetworkCommand ):String;
//        function sendToNearest( command:NetworkCommand, groupAddress:String ):String;
//        function sendToNeighbor( command:NetworkCommand, sendMode:String ):String;
        
        function sendToAll( command:NetworkCommand ):void;
        function sendTo( peerID:String, command:NetworkCommand ):void;
        function sendToUser( name:String, command:NetworkCommand ):void;
    }
}