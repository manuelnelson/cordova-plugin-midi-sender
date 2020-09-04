
var exec = require('cordova/exec');

var MIDISender = function() {};

/**
 * @param {number} channelNum 0-15 
 * @param {number} programNum 1-128
 * @return {void}
 */
MIDISender.greet = function(hi) {
	// add 192 for the 192-207 program change range
    cordova.exec(function(){}, function(){}, "MIDISender", "greet", [hi]);
};
MIDISender.sendProgramChange = function(channelNum, programNum) {
	// add 192 for the 192-207 program change range
	channelNum = parseInt(channelNum) + 191;

    exec(function(){}, function(){}, "MIDISender", "sendProgramChange", [channelNum, programNum]);
};
MIDISender.sendNote = function(channelNum, programNum, valueNum) {
	channelNum = parseInt(channelNum) + 143;
	exec(function(){}, function(){}, "MIDISender", "sendNote", [channelNum, programNum, valueNum]);
};
MIDISender.sendControlChange = function(channelNum, programNum, valueNum) {
	channelNum = parseInt(channelNum) + 175;
	exec(function(){}, function(){}, "MIDISender", "sendControlChange", [channelNum, programNum, valueNum]);
};
MIDISender.connectMidi = function() {
	exec(function(message) {
			console.log(message)
			if(message == "Midi connected")
				return true;
			else 
				return false;
    },function(error){
			alert(error)
		}, "MIDISender", "connectMidi", [])
}
MIDISender.setupMidi = function() {
	exec(function(message) {
			// alert(message)
    },function(error){
			// alert(error)
		}, "MIDISender", "setupMidi", [])
}
MIDISender.getIncomingSync = function(channel, data, value) {
	alert(`${channel} ${data} ${value}`);
}
/**
 * @param {function} callback
 * @return {void}
 */
MIDISender.getIncoming = function(callback) 
{
	exec(
		function(data)
		{
			// For Int -> Note value
            var notes = ['C','C#','D','D#','E','F','F#','G','G#','A','A#','B'];
			
			var dc = parseInt(data.channel);
			if (dc > 191 &&  dc < 208) { // Program Change
            	data.channel = dc - 192;
				data.type = 'Program Change';
            } else if (dc > 143 &&  dc < 160) { // Note
				data.channel = dc - 143;
				var octave = Math.floor(parseInt(data.data) / 12) - 2;
				var remainder = parseInt(data.data) % 12;
				data.data = notes[remainder]+octave;
				data.type = (parseInt(data.value) > 0)? 'Note On': 'Note Off';
			} else if (dc > 175 && dc < 192) { // CC
				data.channel = dc - 175;
				data.type = 'Control Change';
			} 
			else 
			{
				data.channel = dc;
			}
			callback.call(this, data);
		},
		function() {},
		"MIDISender",
		"getIncoming",
	  	{}
	  );
};

exports.module = MIDISender;