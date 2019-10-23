MIDISender
======

This is a fork of [cordova-plugin-midi-sender](https://github.com/jonathanwkelly/cordova-plugin-midi-sender). I added the ability to send/receive MIDI **note** and **CC** message types to [Jonathan's](https://github.com/jonathanwkelly) work.


Installation
-------

NPM:

	cordova plugin add cordova-plugin-midi-sender

Repository:

	cordova plugin add https://github.com/josiaho/cordova-plugin-midi-sender.git

Dependencies
-------

`CoreMIDI.framework` is required, and will be linked for you automatically


Methods
-------

**Listen for incoming MIDI messages on all channels:**
	
	cordova.plugins.MIDISender.getIncoming(function(msg) {
	  if (msg.channel){ // Ignore msg sent on plugin initialization
	  
	    /* MESSAGE DATA
	      msg.channel = MIDI channel (1-16)
	      msg.type = Type of MIDI message: 'Program Change', 'Control Change', 'Note On', 'Note off'
	      msg.data = MIDI Data: <number> for PC/CC (1-128), or Note (i.e. "C3") for Note On/Off
	      msg.value = Not present for 'Program Change' messages
	    */
	    
	  }
	});
	
**Send MIDI Messages:**

    // Send Program Change (Channel, Data)
    cordova.plugins.MIDISender.sendProgramChange(1, 30);
    
    // Send NoteOn (Channel, Data, Value)
    cordova.plugins.MIDISender.sendNote(1, 60, 127); // Ch 1, NoteOn C3, Value
    
    // Send Control Change (Channel, Data, Value)
    cordova.plugins.MIDISender.sendControlChange(1, 1, 1);

Permissions
-----------

    <feature name="MIDISender">
        <param name="ios-package" value="MIDISender" onload="true" />
    </feature>

Debugging
-----------

Debug messages are sent to `NSLog`

Resources
-----------

If you're unfamiliar with MIDI, checkout <a href="http://www.midi.org/techspecs/midimessages.php" target="_blank" title="MIDI Manufacturers Association">this spec</a> on MIDI messages.

Credits
-----------

[Jonathan Kelly](https://github.com/jonathanwkelly/cordova-plugin-midi-sender)