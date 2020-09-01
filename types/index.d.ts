interface MIDISender {
  greet() : void
  sendProgramChange(channelNum:number, programNum:number) : void
  sendNote(channelNum:number, programNum:number, valueNum:number) : void
  sendControlChange(channelNum:number, programNum:number, valueNum:number) : void
  connectMidi() : void
  getIncoming(callback:Function) : void
}