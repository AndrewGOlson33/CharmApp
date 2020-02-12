//
//  SpeechRecognitionModel.swift
//  Charm
//
//  Created by Daniel Pratt on 3/25/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import Accelerate
import Foundation
import Speech

protocol SpeechRecognitionDelegate {
    func speechRecognizerGotText(text: String)
    func speechRecognizerFinished(successfully: Bool)
}

class SpeechRecognitionModel: NSObject {
    
    // MARK: - Properties
    
    // speech recognition properties
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.autoupdatingCurrent)
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private let LEVEL_LOWPASS_TRIG : Float32 = 0.30
    
    private var averagePowerForChannel0 : Float = 0 {
        didSet {
//            print("~>averagePowerForChannel0: ", averagePowerForChannel0)
        }
    }
    private var averagePowerForChannel1 : Float = 0 {
        didSet {
//            print("~>averagePowerForChannel1: ", averagePowerForChannel1)
        }
    }
    var normalizedPowerLevelFromDecibels: CGFloat {
        if (averagePowerForChannel0 < -60.0 || averagePowerForChannel0 == 0.0) {
            return 0.0
        }
        return CGFloat(powf((powf(10.0, 0.05 * averagePowerForChannel0) - powf(10.0, 0.05 * -60.0)) * (1.0 / (1.0 - powf(10.0, 0.05 * -60.0))), 1.0 / 2.0))
    }
    
    // delegate to return recognized speech text
    var delegate: SpeechRecognitionDelegate? = nil
    
    // MARK: - Model Functions
    
    // Recording Task
    
    func checkAuthorization(completion: @escaping(_ authorized: Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { (status) in
            print("~>Status: \(status.rawValue)")
            if status == .authorized {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    func isAvailable() -> Bool {
        return speechRecognizer?.isAvailable ?? false
    }
    
    func isRecording() -> Bool {
        return audioEngine.isRunning
    }
    
    func startRecording() {
        
        guard !audioEngine.isRunning else {
            stopRecording()
            return
        }
        
        // cancel any existing tasks
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: [])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("~>audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        
        // remove old tap (if there was any)
        inputNode.removeTap(onBus: 0)
        
        guard let recognitionRequest = recognitionRequest else {
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, delegate: self)
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
            self.audioMetering(buffer: buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            AudioServicesPlaySystemSound(1113)
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        AudioServicesPlaySystemSound(1114)
        return
    }
    
    // MARK: Private methods
    
    private func audioMetering(buffer:AVAudioPCMBuffer) {
        buffer.frameLength = 1024
        let inNumberFrames:UInt = UInt(buffer.frameLength)
        if buffer.format.channelCount > 0 {
            let samples = (buffer.floatChannelData![0])
            var avgValue:Float32 = 0
            vDSP_meamgv(samples,1 , &avgValue, inNumberFrames)
            var v:Float = -100
            if avgValue != 0 {
                v = 20.0 * log10f(avgValue)
            }
            self.averagePowerForChannel0 = (self.LEVEL_LOWPASS_TRIG*v) + ((1-self.LEVEL_LOWPASS_TRIG)*self.averagePowerForChannel0)
            self.averagePowerForChannel1 = self.averagePowerForChannel0
        }

        if buffer.format.channelCount > 1 {
            let samples = buffer.floatChannelData![1]
            var avgValue:Float32 = 0
            vDSP_meamgv(samples, 1, &avgValue, inNumberFrames)
            var v:Float = -100
            if avgValue != 0 {
                v = 20.0 * log10f(avgValue)
            }
            self.averagePowerForChannel1 = (self.LEVEL_LOWPASS_TRIG*v) + ((1-self.LEVEL_LOWPASS_TRIG)*self.averagePowerForChannel1)
        }
    }
}

// MARK: - Speech Task Delegate

extension SpeechRecognitionModel: SFSpeechRecognitionTaskDelegate {
    
//    func speechRecognitionDidDetectSpeech(_ task: SFSpeechRecognitionTask) {
//        print("~>Detected speech.")
//    }
    
    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didHypothesizeTranscription transcription: SFTranscription) {
        delegate?.speechRecognizerGotText(text: transcription.formattedString)
    }
    
    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishSuccessfully successfully: Bool) {
        delegate?.speechRecognizerFinished(successfully: successfully)
    }
}
