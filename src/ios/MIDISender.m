/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */

#import "MIDISender.h"

NSString* receiveCallbackId;

@interface MIDISender()
    -(void)sendProgramChange:(CDVInvokedUrlCommand *)command;
    -(void)getIncoming:(CDVInvokedUrlCommand *)command;
    //-(void)scanExistingDevices:(NSTimer *)timer;

    @property (nonatomic, retain) NSTimer *rescanTimer;
@end

@implementation MIDISender

    void midiReceive(const MIDIPacketList *list, void *procRef, void *srcRef)
    {
        MIDISender* midiSender = (__bridge MIDISender*)procRef;

        for(UInt32 i = 0; i < list->numPackets; i++)
        {
            const MIDIPacket *packet = &list->packet[i];
            
            for(UInt16 j = 0, size = 0; j < packet->length; j += size)
            {
                UInt8 status = packet->data[j];
                
                //size = 2;
                size = 3;
                
                // @debug
                //NSLog(@"MIDISender:midiReceive: status %d received %d aaaaannd %d", status, packet->data[j + 1], packet->data[j + 2]);
                  // Create an object with a simple success property.
                NSDictionary *jsonObj = [
                    [NSDictionary alloc] initWithObjectsAndKeys: [NSString stringWithFormat:@"%d", status],
                    @"channel",
                    [NSString stringWithFormat:@"%d", packet->data[j + 1]],
                    @"data",
                    [NSString stringWithFormat:@"%d", packet->data[j + 2]],
                    @"value",
                    nil
                ];
                
                CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsDictionary: jsonObj];
                
                [pluginResult setKeepCallbackAsBool:YES];

                [midiSender.commandDelegate sendPluginResult:pluginResult callbackId:receiveCallbackId];
                
                // program change
            //     if(status >= 192 && status <= 207){
            //         // @debug
            //         //NSLog(@"MIDISender:midiReceive: Program Change received: status %d on channel %d", packet->data[j + 1], status);

            //         // Create an object with a simple success property.
            //         NSDictionary *jsonObj = [
            //             [NSDictionary alloc] initWithObjectsAndKeys: [NSString stringWithFormat:@"%d", status], 
            //             @"channel", 
            //             [NSString stringWithFormat:@"%d", packet->data[j + 1]], 
            //             @"data", 
            //             nil
            //         ];
                    
            //         CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsDictionary: jsonObj];
                    
            //         [pluginResult setKeepCallbackAsBool:YES];

            //         [midiSender.commandDelegate sendPluginResult:pluginResult callbackId:receiveCallbackId];
            //     } else if(status >= 144 && status <= 159){ // Note
            //         // @debug
            //         //NSLog(@"MIDISender:midiReceive: Note received: status %d on channel %d", packet->data[j + 1], status);

            //         // Create an object with a simple success property.
            //         NSDictionary *jsonObj = [
            //             [NSDictionary alloc] initWithObjectsAndKeys: [NSString stringWithFormat:@"%d", status],
            //             @"channel",
            //             [NSString stringWithFormat:@"%d", packet->data[j + 1]],
            //             @"data",
            //             [NSString stringWithFormat:@"%d", packet->data[j + 2]],
            //             @"value",
            //             nil
            //         ];
                    
            //         CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsDictionary: jsonObj];
                    
            //         [pluginResult setKeepCallbackAsBool:YES];

            //         [midiSender.commandDelegate sendPluginResult:pluginResult callbackId:receiveCallbackId];
            //     } else if(status >= 176 && status <= 191){ // CC
            //        // @debug
            //         //NSLog(@"MIDISender:midiReceive: CC Channel %d Data %d Value %d", status, packet->data[j + 1], packet->data[j + 2]);

            //        // Create an object with a simple success property.
            //        NSDictionary *jsonObj = [
            //            [NSDictionary alloc] initWithObjectsAndKeys: [NSString stringWithFormat:@"%d", status],
            //            @"channel",
            //            [NSString stringWithFormat:@"%d", packet->data[j + 1]],
            //            @"data",
            //            [NSString stringWithFormat:@"%d", packet->data[j + 2]],
            //            @"value",
            //            nil
            //        ];
                   
            //        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsDictionary: jsonObj];
                   
            //        [pluginResult setKeepCallbackAsBool:YES];

            //        [midiSender.commandDelegate sendPluginResult:pluginResult callbackId:receiveCallbackId];
            //    }
            }
        }
    }

    - (void)pluginInitialize
    {
        // create the client
        OSStatus s = MIDIClientCreate(CFSTR("MIDISender Client"), nil, nil, &client);
        
        // create the output port
        s = MIDIOutputPortCreate(client, CFSTR("MIDISender Output Port"), &outputPort);

        // @debug
        NSLog(@"MIDISender:pluginInitialize: Creating MIDI client (errCode=%d)", (int)s);
        NSLog(@"MIDISender:pluginInitialize: Creating MIDI output port (errCode=%d)", (int)s);
        NSLog(@"MIDISender:pluginInitialize: %lu MIDI destinations found", MIDIGetNumberOfDestinations());
    }

    - (void)sendProgramChange:(CDVInvokedUrlCommand *)command
    {
        // run as background thread
        [self.commandDelegate runInBackground:^{
    
            int channelNum = [[command.arguments objectAtIndex:0] intValue];
            int programNum = [[command.arguments objectAtIndex:1] intValue];
            
            // Program Change
            // see: http://www.midi.org/techspecs/midimessages.php
            // Byte 1 - Channel #: 0xCn, n = channel number 0-F, channel 10 is represented by 0xCA
            // Byte 2 - Program #: 1-128

            const Byte message[] = {channelNum, programNum};

            MIDIPacketList packetList;
            MIDIPacket *packet = MIDIPacketListInit(&packetList);
            MIDIPacketListAdd(&packetList, sizeof(packetList), packet, 0, sizeof(message), message);

            ItemCount destinationCount = MIDIGetNumberOfDestinations();
            for(int i = 0; i < destinationCount; i++)
            {
                // @debug
                NSLog(@"MIDISender:sendProgramChange: Sending status %d to channel %d at destination %d", programNum, channelNum, i);
                
                MIDISend(outputPort, MIDIGetDestination(i), &packetList);
            }
            
            // Create an object with a simple success property.
            NSDictionary *jsonObj = [[NSDictionary alloc] initWithObjectsAndKeys: @"true", @"success", nil];
            
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsDictionary: jsonObj];
        
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }];
    }

    - (void)sendNote:(CDVInvokedUrlCommand *)command
       {
           // run as background thread
           [self.commandDelegate runInBackground:^{
       
               int channelNum = [[command.arguments objectAtIndex:0] intValue];
               int programNum = [[command.arguments objectAtIndex:1] intValue];
               int valueNum = [[command.arguments objectAtIndex:2] intValue];
               
               // Program Change
               // see: http://www.midi.org/techspecs/midimessages.php
               // Byte 1 - Channel #: 0xCn, n = channel number 0-F, channel 10 is represented by 0xCA
               // Byte 2 - Program #: 1-128

               const Byte message[] = {channelNum, programNum, valueNum};

               MIDIPacketList packetList;
               MIDIPacket *packet = MIDIPacketListInit(&packetList);
               MIDIPacketListAdd(&packetList, sizeof(packetList), packet, 0, sizeof(message), message);

               ItemCount destinationCount = MIDIGetNumberOfDestinations();
               for(int i = 0; i < destinationCount; i++)
               {
                   // @debug
                   //NSLog(@"MIDISender:sendProgramChange: Sending status %d to channel %d at destination %d", programNum, channelNum, i);
                   
                   MIDISend(outputPort, MIDIGetDestination(i), &packetList);
               }
               
               // Create an object with a simple success property.
               NSDictionary *jsonObj = [[NSDictionary alloc] initWithObjectsAndKeys: @"true", @"success", nil];
               
               CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsDictionary: jsonObj];
           
               [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
           }];
       }

    - (void)sendControlChange:(CDVInvokedUrlCommand *)command
    {
        // run as background thread
        [self.commandDelegate runInBackground:^{
    
            int channelNum = [[command.arguments objectAtIndex:0] intValue];
            int programNum = [[command.arguments objectAtIndex:1] intValue];
            int valueNum = [[command.arguments objectAtIndex:2] intValue];
            
            // Program Change
            // see: http://www.midi.org/techspecs/midimessages.php
            // Byte 1 - Channel #: 0xCn, n = channel number 0-F, channel 10 is represented by 0xCA
            // Byte 2 - Program #: 1-128

            const Byte message[] = {channelNum, programNum, valueNum};

            MIDIPacketList packetList;
            MIDIPacket *packet = MIDIPacketListInit(&packetList);
            MIDIPacketListAdd(&packetList, sizeof(packetList), packet, 0, sizeof(message), message);

            ItemCount destinationCount = MIDIGetNumberOfDestinations();
            for(int i = 0; i < destinationCount; i++)
            {
                // @debug
                //NSLog(@"MIDISender:sendProgramChange: Sending status %d to channel %d at destination %d", programNum, channelNum, i);
                
                MIDISend(outputPort, MIDIGetDestination(i), &packetList);
            }
            
            // Create an object with a simple success property.
            NSDictionary *jsonObj = [[NSDictionary alloc] initWithObjectsAndKeys: @"true", @"success", nil];
            
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsDictionary: jsonObj];
        
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }];
    }
    - (void)scanExistingDevices:(NSTimer *)timer
    {

        // CDVInvokedUrlCommand *command = [timer userInfo];   // @debug
        // NSString* consoleLog = [NSString stringWithFormat:@"console.log( %@ )",command.callbackId];
        [self.commandDelegate evalJs:@"console.log('foo')"];

        // NSLog(@"MIDISender:getIncoming was called");
        // create the input port
        // OSStatus s = MIDIInputPortCreate(client, CFSTR("MIDISender Input Port"), midiReceive, (__bridge void *)(self), &inputPort);

        // @debug
        // NSLog(@"MIDISender:getIncoming: Creating MIDI input port (errCode=%d)", (int)s);
        
        // attach to all devices for input
        // ItemCount DeviceCount = MIDIGetNumberOfDevices();
        
        // @debug
        // NSLog(@"MIDISender:getIncoming: %lu MIDI devices found", DeviceCount);

        // for(ItemCount i = 0; i < DeviceCount; i++)
        // {
        //     MIDIEndpointRef src = MIDIGetSource(i);
        //     MIDIPortConnectSource(inputPort, src, NULL);
        // }
        
        // if(receiveCallbackId == nil)
        // {
        //     receiveCallbackId = command.callbackId;
            
        //     // @debug
        //     NSLog(@"MIDISender:getIncoming: receiveCallbackId has been set to %@", receiveCallbackId);
            
        //     CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsString: @"Initialized"];
        
        //     [pluginResult setKeepCallbackAsBool:YES];

        //     [self.commandDelegate sendPluginResult:pluginResult callbackId:receiveCallbackId];
        // }
    }
    - (void)getIncoming:(CDVInvokedUrlCommand *)command
    {
        // run as background thread'
        [self.commandDelegate runInBackground:^{
            self.rescanTimer = [NSTimer  scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(scanExistingDevices:) userInfo:nil repeats:YES];
           
        }];
    }
    - (void) dealloc
    {   
        [_rescanTimer invalidate];
        self.rescanTimer = nil;
    }
@end
