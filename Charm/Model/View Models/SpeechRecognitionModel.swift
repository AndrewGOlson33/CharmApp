//
//  SpeechRecognitionModel.swift
//  Charm
//
//  Created by Daniel Pratt on 3/25/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

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
