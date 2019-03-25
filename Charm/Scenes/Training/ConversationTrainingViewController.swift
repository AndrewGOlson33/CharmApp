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
    @IBOutlet weak var tableView: UITableView!
    
    // buttons
    
    @IBOutlet weak var btnReplay: UIImageView!
    @IBOutlet weak var btnRecordStop: UIImageView!
    @IBOutlet weak var btnScoreReset: UIImageView!
    
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
    
    // Detect if we are in score or reset mode
    private var shouldReset = false
    
    // Button Images
    
    let mic = UIImage(named: Image.Mic)!
    let stop = UIImage(named: Image.Stop)!
    let chart = UIImage(named: Image.Chart)!
    let reset = UIImage(named: Image.Reset)!
    
    // MARK: - View Lifecycle Functions

    override func viewDidLoad() {
        super.viewDidLoad()

        // Load initial prompts
        updatePrompts()
        
        txtReply.delegate = self
        txtReply.textColor = .lightGray
        txtReply.text = "tap microphone to respond to prompt"
        
        // Setup Button Taps
        
//        let replayTap = UITapGestureRecognizer(target: self, action: <#T##Selector?#>)
//        btnReplay.isUserInteractionEnabled = true
        
        let recordStopTap = UITapGestureRecognizer(target: self, action: #selector(recordButtonTapped(_:)))
        recordStopTap.numberOfTapsRequired = 1
        recordStopTap.numberOfTouchesRequired = 1
        btnRecordStop.addGestureRecognizer(recordStopTap)
        btnRecordStop.isUserInteractionEnabled = true
        
        let scoreResetTap = UITapGestureRecognizer(target: self, action: #selector(scoreLoadButtonTapped(_:)))
        scoreResetTap.numberOfTapsRequired = 1
        scoreResetTap.numberOfTouchesRequired = 1
        btnScoreReset.addGestureRecognizer(scoreResetTap)
        btnScoreReset.isUserInteractionEnabled = true
        
    }
    
    // MARK: - UI Setup Functions
    private func updatePrompts() {
        
        guard let prompt = trainingViewModel.getRandomConversationPrompt() else { return }
        UIView.animate(withDuration: 0.25, animations: {
            self.lblYouSaid.alpha = 0
            self.lblTheySaid.alpha = 0
            self.txtReply.textColor = .lightGray
            self.txtReply.text = "tap microphone to respond to prompt"
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
            UIView.animate(withDuration: 0.25, animations: {
                self.btnRecordStop.alpha = 0
            }) { (_) in
                self.btnRecordStop.image = self.mic
                UIView.animate(withDuration: 0.25, animations: {
                    self.btnRecordStop.alpha = 1.0
                })
            }
            
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
        
        // make sure recording has ended first
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            AudioServicesPlaySystemSound(1114)
            UIView.animate(withDuration: 0.25, animations: {
                self.btnRecordStop.alpha = 0
            }) { (_) in
                self.btnRecordStop.image = self.mic
                UIView.animate(withDuration: 0.25, animations: {
                    self.btnRecordStop.alpha = 1.0
                })
            }
        }
        
        if !shouldReset, let text = txtReply.text {
            if text == "tap microphone to respond to prompt" {
                let alert = UIAlertController(title: "Tap Microphone", message: "You must record a response before you can score it.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                present(alert, animated: true, completion: nil)
                return
            }
            
            trainingViewModel.score(response: text)
            tableView.reloadData()
            shouldReset = true
        } else {
            updatePrompts()
            shouldReset = false
        }
        
        
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
            UIView.animate(withDuration: 0.25, animations: {
                self.btnRecordStop.alpha = 0
            }) { (_) in
                self.btnRecordStop.image = self.stop
                UIView.animate(withDuration: 0.25, animations: {
                    self.btnRecordStop.alpha = 1.0
                })
            }
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
    }

}

// MARK: - Table View Delegate Functions

extension ConversationTrainingViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 8
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellID.ScaleBar, for: indexPath) as! ScaleBarTableViewCell
        
        switch indexPath.row {
        case 0:
            let strength = trainingViewModel.strength
            cell.lblDescription.text = "Estimated Phrase Strength"
            cell.scaleBar.setupBar(ofType: .Green, withValue: Double(strength.score), andLabelPosition: strength.position)
        case 1:
            let length = trainingViewModel.length
            cell.lblDescription.text = "Phrase Length"
            cell.scaleBar.setupBar(ofType: .BlueRight, withValue: Double(length.score), andLabelPosition: length.position)
        case 2:
            let concrete = trainingViewModel.concrete
            cell.lblDescription.text = "Concrete Details"
            cell.scaleBar.setupBar(ofType: .BlueRight, withValue: Double(concrete.score), andLabelPosition: concrete.position)
        case 3:
            let abstract = trainingViewModel.abstract
            cell.lblDescription.text = "Abstract Ideas"
            cell.scaleBar.setupBar(ofType: .BlueRight, withValue: Double(abstract.score), andLabelPosition: abstract.position)
        case 4:
            let first = trainingViewModel.first
            cell.lblDescription.text = "First Person (\"I/\"Me\")"
            cell.scaleBar.setupBar(ofType: .BlueRight, withValue: Double(first.score), andLabelPosition: first.position)
        case 5:
            let second = trainingViewModel.second
            cell.lblDescription.text = "Second Person (\"You\")"
            cell.scaleBar.setupBar(ofType: .BlueRight, withValue: Double(second.score), andLabelPosition: second.position)
        case 6:
            let positive = trainingViewModel.positive
            cell.lblDescription.text = "Positive Word Score"
            cell.scaleBar.setupBar(ofType: .BlueRight, withValue: Double(positive.score), andLabelPosition: positive.position)
        case 7:
            let negative = trainingViewModel.negative
            cell.lblDescription.text = "Negative Word Score"
            cell.scaleBar.setupBar(ofType: .RedRightQuarter, withValue: Double(negative.score), andLabelPosition: negative.position)
        default:
            print("~>Should not be possible to get here.")
        }
        
        return cell
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
        textView.text = textView.text == "tap microphone to respond to prompt" ? "" : textView.text
        view.frame.origin.y -= view.frame.height / 3
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty || textView.text == "" {
            textView.textColor = .lightGray
            textView.text = "tap microphone to respond to prompt"
        }
        
        view.frame.origin.y = 0
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        } else {
            return true
        }
    }
    
}
