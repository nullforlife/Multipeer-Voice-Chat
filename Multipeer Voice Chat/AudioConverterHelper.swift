//
//  AudioConverterHelper.swift
//  Multipeer Voice Chat
//
//  Created by Oskar Jönsson on 2016-10-10.
//  Copyright © 2016 Oskar Jönsson. All rights reserved.
//

import Foundation
import AVFoundation

class AudioConverterHelper {
    
    static func copyAudioBufferBytes(_ audioBuffer: AVAudioPCMBuffer) -> [UInt8] {
        let srcLeft = audioBuffer.floatChannelData![0]
        let bytesPerFrame = audioBuffer.format.streamDescription.pointee.mBytesPerFrame
        let numBytes = Int(bytesPerFrame * audioBuffer.frameLength)
        
        
        var audioByteArray = [UInt8](repeating: 0, count: numBytes)
        
        srcLeft.withMemoryRebound(to: UInt8.self, capacity: numBytes) { srcByteData in
            audioByteArray.withUnsafeMutableBufferPointer {
                $0.baseAddress!.initialize(from: srcByteData, count: numBytes)
            }
        }
        return audioByteArray
    }
    
    
    static func bytesToAudioBuffer(_ buf: [UInt8]) -> AVAudioPCMBuffer {
        
        let audioFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 8000, channels: 1, interleaved: false)
        
        let frameLength = UInt32(buf.count) / audioFormat.streamDescription.pointee.mBytesPerFrame
        
        let audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameLength)
        audioBuffer.frameLength = frameLength
        
        let dstLeft = audioBuffer.floatChannelData![0]
        
        
        buf.withUnsafeBufferPointer {
            let src = UnsafeRawPointer($0.baseAddress!).bindMemory(to: Float.self, capacity: Int(frameLength))
            dstLeft.initialize(from: src, count: Int(frameLength))
        }
        
        return audioBuffer
    }
}
