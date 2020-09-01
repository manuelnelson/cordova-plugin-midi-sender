interface MIDISender {
  greet()
  sendProgramChange(channelNum:number, programNum:number)
  sendNote(channelNum:number, programNum:number, valueNum:number)
  sendControlChange(channelNum:number, programNum:number, valueNum:number)
  connectMidi()
  getIncoming(callback:Function)
}