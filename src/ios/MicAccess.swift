//
//  channelMic.swift
//  MicTest
//
//  Created by Geordie Jay on 14.11.14.
//

import Foundation

@objc(MicAccess) class MicAccess : CDVPlugin, EZMicrophoneDelegate {
    
    let bufferSize: Int = 8192 // = 2048 audio samples, buffer length 46.4 ms
    var _circularBuffer = UnsafeMutablePointer<TPCircularBuffer>.alloc(1)
    var outputBuffer = NSMutableData()
    
    override func pluginInitialize () {
        
        EZAudio.circularBuffer(_circularBuffer, withSize: Int32(bufferSize))
        outputBuffer = NSMutableData(length: bufferSize)!

        let mic = EZMicrophone.sharedMicrophone()
        let asbd = EZAudio.stereoFloatNonInterleavedFormatWithSampleRate(88200)// CanonicalFormatWithSampleRate(88200)
        mic.setAudioStreamBasicDescription(asbd) // when we do this, the buffer doesn't get updated
        
        let flags = asbd.mFormatFlags
        if flags & AudioFormatFlags(kAudioFormatFlagIsFloat) != 0 {
            println("We're working with floating point audio")
        } else {
            println("We're working with integer audio")
        }
        
        EZAudio.printASBD(mic.audioStreamBasicDescription())
        mic.microphoneDelegate = self
        mic.startFetchingAudio()
        
    }
    
    // The microphone function makes the MicAccess class conform to EZMicrophoneDelegate Protocol
    // - we need this so we can use 'self' as the microphoneDelegate (and get callbacks from the mic data)
    
    // Append the AudioBufferList from the microphone callback to a global circular buffer
    func microphone (EZMicrophone, hasBufferList bufferList: UnsafeMutablePointer<AudioBufferList>,
        withBufferSize bufferSize: UInt32, withNumberOfChannels numberOfChannels: UInt32) {
            
//            let list = bufferList.memory
//            let audioData = list.mBuffers.mData
//            let bufferLength = list.mBuffers.mDataByteSize
            
            // Append the audio data to a circular buffer
            EZAudio.appendDataToCircularBuffer(_circularBuffer, fromAudioBufferList: bufferList)

    }
    
    
    func getBuffer(command: CDVInvokedUrlCommand) {
        
        // This function combines the current state of two buffers that are already in memory
        
        // We return a single ArrayBuffer with two halves:
        // 1st Half (Waveform Time Domain): Signed Float32 2048 samples (= 8192 bytes),
        // 2nd Half (FFT Frequency Domain): Unsigned Float32 1024 samples (= 4096 bytes)
        
        // XXX: allow user to ask for just one of the two buffers via an arg
        //var args = command.arguments[0] as String
        
        commandDelegate.runInBackground {
        
            // Get the available bytes in the circular buffer
            var availableBytes: Int32 = 0 // this value gets set by pointer in TPCircularBufferTail below
            var buffer: UnsafeMutablePointer<Void> = TPCircularBufferTail(self._circularBuffer, &availableBytes);
            
            // Hopefully we have a full buffer, but see if availableBytes is less than the desired buffer size
            let amount: Int32 = self.MIN(Int32(self.bufferSize), y: availableBytes);
            
            // Copy the bytes into an NSData object for output via Cordova
            let availableAudioRange = NSRange(location: 0, length: Int(availableBytes))
            self.outputBuffer.replaceBytesInRange(availableAudioRange, withBytes: buffer, length: Int(availableBytes))
            
            // Consume those bytes ( internally push the head of the circular buffer )
            // XXX: See if we can put the following in the getBuffer statement, it may be more efficient
            TPCircularBufferConsume(self._circularBuffer, amount)
            
            let bufferResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsArrayBuffer: self.outputBuffer)
            self.commandDelegate.sendPluginResult(bufferResult, callbackId:command.callbackId)
        }
        
    }
    
    
    
    func MIN (x: Int32, y: Int32) -> Int32 {
        return x < y ? x : y
    }
    
    deinit {
        TPCircularBufferClear(_circularBuffer);
    }
}



