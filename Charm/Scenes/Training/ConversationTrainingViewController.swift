//
//  ConversationTrainingViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 3/22/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit
import Speech

class ConversationTrainingViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var lblYouSaid: UILabel!
    @IBOutlet weak var lblTheySaid: UILabel!
    @IBOutlet weak var txtReply: UITextView!
    
    // Layout Constraints
    @IBOutlet weak var setHighIfOnlyTheySaid: NSLayoutConstraint!
    @IBOutlet weak var setLowIfOnlyTheySaid: NSLayoutConstraint!
    
    // MARK: - Properties
    
    // View Models
    var trainingViewModel: ChatTrainingViewModel = ChatTrainingViewModel()
    
    // Speech Recognition Properties
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.autoupdatingCurrent)
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // MARK: - View Lifecycle Functions

    override func viewDidLoad() {
        super.viewDidLoad()

        // Load initial prompts
        updatePrompts()
        
        txtReply.delegate = self
        txtReply.textColor = .lightGray
        txtReply.text = "tap microphone to respond to prompt"
    }
    
    // MARK: - UI Setup Functions
    private func updatePrompts() {
        
        guard let prompt = trainingViewModel.getRandomPrompt() else { return }
        UIView.animate(withDuration: 0.25, animations: {
            self.lblYouSaid.alpha = 0
            self.lblTheySaid.alpha = 0
        }) { (_) in
            let theySaid = prompt.theySaid
            self.lblTheySaid.text = "They said: \(theySaid)"
            
            if let youSaid = prompt.youSaid {
                self.lblYouSaid.text = "You said: \(youSaid)"
                self.lblYouSaid.isHidden = false
                UIView.animate(withDuration: 0.25, animations: {
                    self.lblYouSaid.alpha = 1.0
                    self.lblTheySaid.alpha = 1.0
                    self.setLowIfOnlyTheySaid.priority = .defaultHigh
                    self.setHighIfOnlyTheySaid.priority = .defaultLow
                    self.view.layoutIfNeeded()
                })
            } else {
                self.lblYouSaid.isHidden = true
                self.setLowIfOnlyTheySaid.priority = .defaultLow
                self.setHighIfOnlyTheySaid.priority = .defaultHigh
                self.lblTheySaid.alpha = 1.0
                self.view.layoutIfNeeded()
            }
        }
    }
    

    // MARK: - Button Handling
    
    @IBAction func recordButtonTapped(_ sender: Any) {
        
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            AudioServicesPlaySystemSound(1114)
            return
        }
        
        SFSpeechRecognizer.requestAuthorization { (status) in
            print("~>Status: \(status.rawValue)")
        }
        
        if speechRecognizer?.isAvailable ?? false {
            startRecording()
        } else {
            let alert = UIAlertController(title: "Not Available", message: "Speech recogniztion is not currently available.  Please check your internet connection and try again.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    // Score or Load New Prompts
    @IBAction func scoreLoadButtonTapped(_ sender: Any) {
        
        if let text = txtReply.text {
            trainingViewModel.score(response: text)
        }
        
        
        updatePrompts()
    }
    
    // MARK: - Private Helper Functions
    
    // Recording Task
    private func startRecording() {
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

}

// MARK: - Speech Task Delegate

extension ConversationTrainingViewController: SFSpeechRecognitionTaskDelegate {
    
    func speechRecognitionDidDetectSpeech(_ task: SFSpeechRecognitionTask) {
        print("~>Detected speech.")
    }
    
    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didHypothesizeTranscription transcription: SFTranscription) {
        txtReply.textColor = .black
        txtReply.text = transcription.formattedString
    }
    
}

// MARK: - TextView Delegate

extension ConversationTrainingViewController: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.textColor = .black
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty || textView.text == "" {
            textView.textColor = .lightGray
            textView.text = "tap microphone to respond to prompt"
        }
    }
    
}
