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
package com.emmanuelnelson;

import java.io.IOException;
import org.apache.cordova.*;
import android.content.Context;

// import android.media.midi.MidiDevice;
// import android.media.midi.MidiDeviceInfo;
// import android.media.midi.MidiInputPort;
// import android.media.midi.MidiManager;
import android.media.midi.*;
// import android.media.midi.MidiOutputPort;
import android.Manifest;
import android.os.Looper;
import android.os.Handler;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;


/**
 * This class called by CordovaActivity to play and record audio.
 * The file can be local or over a network using http.
 *
 * Audio formats supported (tested):
 * 	.mp3, .wav
 *
 * Local audio files must reside in one of two places:
 * 		android_asset: 		file name must start with /android_asset/sound.mp3
 * 		sdcard:				file name is just sound.mp3
 */


 public class MIDISender extends CordovaPlugin {

    public static String TAG = "MIDISender";

    public static final int PERMISSION_DENIED_ERROR = 20;

    private String recordId;
    private String fileUriStr;

    private MidiManager manager;
    private MidiDevice device;
    private MidiInputPort inputPort;
    private MidiOutputPort output;
    private MidiDeviceInfo info;
    private CallbackContext callbackContext;
    /**
     * Constructor.
     */
    public MIDISender() {
    }

    /**
     * Executes the request and returns PluginResult.
     * @param action 		The action to execute.
     * @param args 			JSONArry of arguments for the plugin.
     * @param callbackContext		The callback context used when calling back into JavaScript.
     * @return 				A PluginResult object with a status and message.
     */
    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        this.callbackContext = callbackContext;
        if(action.equals("sendProgramChange")) {
            int channelNum = args.getInt(0);
            int programNum = args.getInt(1);
            this.sendProgramChange(channelNum,programNum);
        }
        else if(action.equals("sendNote")) {
            int channelNum = args.getInt(0);
            int programNum = args.getInt(1);
            int value = args.getInt(2);
            this.sendNote(channelNum,programNum, value, callbackContext);
        }
        else if(action.equals("sendControlChange")) {
            int channelNum = args.getInt(0);
            int programNum = args.getInt(1);
            int value = args.getInt(2);
            this.sendNote(channelNum,programNum, value, callbackContext);
        }
        else if(action.equals("setupMidi")) {            
            return this.setupMidi(callbackContext);
        }
        else if(action.equals("connectMidi")) {
            return this.openMidiDevice(callbackContext);
        }
        else if(action.equals("getIncoming")) {
            int commandInt = args.getInt(0);
            this.getIncoming(commandInt, callbackContext);
        }
        else { // Unrecognized action.
            return false;
        }
        return true;
    }

    /**
     * Stop all audio players and recorders.
     */
    public void onDestroy() {
    }

    /**
     * Stop all audio players and recorders on navigate.
     */
    @Override
    public void onReset() {
        onDestroy();
    }

    /**
     * Called when a message is sent to plugin.
     *
     * @param id            The message id
     * @param data          The message data
     * @return              Object to stop propagation or null
     */
    public Object onMessage(String id, Object data) {
        // If phone message
        if (id.equals("telephone")) {
            // If phone ringing, then pause playing
            if ("ringing".equals(data) || "offhook".equals(data)) {
            }
            else if ("idle".equals(data)) {
            }
        }
        return null;
    }

    //--------------------------------------------------------------------------
    // LOCAL METHODS
    //--------------------------------------------------------------------------
    boolean setupMidi(CallbackContext callbackContext) {
        class MyReceiver extends MidiReceiver {
            public void onSend(byte[] data, int offset,
                    int count, long timestamp) throws IOException {
                    // parse MIDI or whatever
                    int channel = data[0];
                    int midiData = data[1];
                    int value = data[2];
                    MIDISender.this.executeGlobalJavascript("MIDISender.module.getIncomingSync(" + String.valueOf(channel) + ", " + String.valueOf(midiData) +  "," + String.valueOf(value) + ")");
            }
        }
        Context context=this.cordova.getActivity().getApplicationContext(); 
        this.manager = (MidiManager)context.getSystemService(Context.MIDI_SERVICE);
        this.manager.registerDeviceCallback(new MidiManager.DeviceCallback() {
            public void onDeviceAdded( MidiDeviceInfo info ) {
                MIDISender.this.info = info;
                this.manager.openDevice(this.info, new MidiManager.OnDeviceOpenedListener() {
                    @Override
                    public void onDeviceOpened(MidiDevice device) {
                        if (device == null) {
                            callbackContext.success("Could not open device");
                        } else {
                            MIDISender.this.device = device;
                            MidiOutputPort outputPort = device.openOutputPort(0);
                            if(outputPort == null) {
                                PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, "No output port"); 
                                MIDISender.this.callbackContext.sendPluginResult(pluginResult);
                            } else {
                                outputPort.connect(new MyReceiver());
                            }
                        }
                    }
                }, new Handler(Looper.getMainLooper()));
            }
        }, new Handler(Looper.getMainLooper()) );
        return true;
    }
    private void executeGlobalJavascript(final String jsString){
        cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                webView.loadUrl("javascript:" + jsString);
            }
        });
    }
    boolean openMidiDevice(CallbackContext callbackContext) {
        return true;
    }

    void sendProgramChange(int channelNum, int programNum) {
        //TODO: Find android implementation of this.

    }
    void sendNote(int channelNum, int programNum, int value, CallbackContext callbackContext) {
        if(this.device == null)
            return;
        if(this.inputPort == null) {
            this.inputPort = this.device.openInputPort(0);
        }
        byte[] buffer = new byte[32];
        int numBytes = 0;
        int channel = 3; // MIDI channels 1-16 are encoded as 0-15.
        buffer[numBytes++] = (byte)(0x90 + (channelNum - 1)); // note on
        buffer[numBytes++] = (byte)programNum; // pitch is middle C
        buffer[numBytes++] = (byte)value; // max velocity
        int offset = 0;
        // post is non-blocking
        try {
            this.inputPort.send(buffer, offset, numBytes);
        } catch(IOException e) {
            e.printStackTrace();
        }
    }

    void getIncoming(int commandId, CallbackContext callbackContext) {
        //tbd

       
    }


}
