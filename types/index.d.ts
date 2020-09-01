import { MIDISender } from "../www/midisender";

// import { MIDISender } from "../www/midisender";
declare namespace MIDISender {
  function greet() : void
  function sendProgramChange(channelNum:number, programNum:number) : void
  function sendNote(channelNum:number, programNum:number, valueNum:number) : void
  function sendControlChange(channelNum:number, programNum:number, valueNum:number) : void
  function connectMidi() : void
  function getIncoming(callback:(data:any) => void) : void
  // interface MIDISender {
  // }
  
}


export {MIDISender}