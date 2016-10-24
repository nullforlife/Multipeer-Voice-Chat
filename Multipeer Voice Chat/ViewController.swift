//
//  ViewController.swift
//  Multipeer Voice Chat
//
//  Created by Oskar Jönsson on 2016-10-10.
//  Copyright © 2016 Oskar Jönsson. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation
import MultipeerConnectivity

class ViewController: UIViewController, StreamDelegate {

    var inputStream : InputStream!
    var outputStream : OutputStream!
    
    var audioSession : AVAudioSession = AVAudioSession.sharedInstance()
    var audioPlayer : AVAudioPlayerNode = AVAudioPlayerNode()
    var engine : AVAudioEngine = AVAudioEngine()
    var mainMixer : AVAudioMixerNode!
    var audioFormat : AVAudioFormat!
    
    var multipeerHandler : MultipeerHandler!
    
    @IBOutlet weak var onlineStatus: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        audioFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 8000, channels: 1, interleaved: false)
        multipeerHandler = MultipeerHandler(sender: self)
        multipeerHandler.joinSession()
        multipeerHandler.startHosting()
        mainMixer = engine.mainMixerNode
        
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: .duckOthers)
            try audioSession.setMode(AVAudioSessionModeVoiceChat)
            try audioSession.setPreferredSampleRate(8000.00)
            try audioSession.setActive(true)
            
            audioSession.requestRecordPermission() { [unowned self] (allowed: Bool) -> Void in
                DispatchQueue.main.async {
                    if allowed {
                    }
                }
            }
            
            
        } catch let error {
            print(error.localizedDescription)
        }
    }

    
    @IBAction func speakButtonTouchDown(_ sender: UIButton) {
        engine.stop()
        let input = self.engine.inputNode!
        let mixer = AVAudioMixerNode()
        engine.attach(mixer)
        engine.connect(input, to: mixer, format: input.inputFormat(forBus: 0))
        mixer.volume = 0
        engine.connect(mixer, to: mainMixer, format: audioFormat)
        
        do {
            
            if multipeerHandler.mcSession.connectedPeers.count > 0 {
                
                if outputStream != nil {
                    outputStream = nil
                }
                
                outputStream = try multipeerHandler.mcSession.startStream(withName: "voice", toPeer: multipeerHandler.mcSession.connectedPeers[0] as MCPeerID)
                outputStream.delegate = self
                outputStream.schedule(in: RunLoop.main, forMode: .defaultRunLoopMode)
                outputStream.open()
                
                try engine.start()
                
                mixer.installTap(onBus: 0, bufferSize: 1024, format: audioFormat, block: {
                    (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
                    
                    let bytes = AudioConverterHelper.copyAudioBufferBytes(buffer)
                    if(self.outputStream.hasSpaceAvailable){
                        self.outputStream.write(bytes, maxLength: bytes.count)
                    }
                })
            }
        } catch let error {
            print(error.localizedDescription)
        }
        
    }
    
    
    @IBAction func speakButtonTouchUpInside(_ sender: UIButton) {
        
        if outputStream != nil {
            outputStream.close()
            engine.stop()
        }
        
    }
    
    var bytesArrayArray : [[UInt8]?] = []

    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
            
        case Stream.Event.errorOccurred:
            break
            
        case Stream.Event.endEncountered:
            print("closed")
            engine.stop()
            audioPlayer.stop()
            inputStream.close()
            inputStream.remove(from: RunLoop.main, forMode: .defaultRunLoopMode)
            break
            
        case Stream.Event.hasBytesAvailable:
            
            do {
                try engine.start()
                audioPlayer.play()
                
            }catch let error {
                print(error.localizedDescription)
            }
            
            var bytes = [UInt8](repeating: 0, count: 4)
            let stream = aStream as! InputStream
            
            stream.read(&bytes, maxLength: bytes.count)
            
            if bytesArrayArray.count < 1024 {
                bytesArrayArray.append(bytes)
                
                
            } else {
                
                var resultBuffer = [UInt8](repeating: 0, count: 4096)
                var index = 0
                
                for byteArrayElement in bytesArrayArray {
                    
                    for byte in byteArrayElement! {
                        resultBuffer[index] = byte
                        index = index + 1
                    }
                }
                
                let audioBuffer = AudioConverterHelper.bytesToAudioBuffer(resultBuffer)
                bytesArrayArray = []
                audioPlayer.scheduleBuffer(audioBuffer, completionHandler: nil)
                audioPlayer.play()
                
            }
            break
            
        case Stream.Event.hasSpaceAvailable:
            break
            
        case Stream.Event.openCompleted:
            break
            
        default:
            print("default")
        }
    }

}

