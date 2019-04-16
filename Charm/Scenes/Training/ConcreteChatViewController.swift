//
//  ConcreteChatViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 3/25/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit
import Speech
import AVKit
import MediaPlayer

class ConcreteChatViewController: UIViewController {

    // MARK: - IBOutlets
    
    @IBOutlet weak var lblWord: UILabel!
    @IBOutlet weak var txtReply: UITextView!
    @IBOutlet weak var tableView: UITableView!
    
    // buttons
    
    @IBOutlet weak var btnReplay: UIImageView!
    @IBOutlet weak var btnRecordStop: UIImageView!
    @IBOutlet weak var btnScoreReset: UIImageView!
    
    // MARK: - Properties
    
    // View Models
    var trainingViewModel: ChatTrainingViewModel = ChatTrainingViewModel()
    var speechModel: SpeechRecognitionModel = SpeechRecognitionModel()
    
    // For speaking text
    var speaker: AVSpeechSynthesizer!
    let audioSession = AVAudioSession.sharedInstance()
    var volumeWasZero = false
    
    private struct Observation {
        static let VolumeKey = "outputVolume"
        static var Context = 0
    }
    
    // Detect if we are in score or reset mode
    private var shouldReset = false
    
    // Button Images
    
    let mic = UIImage(named: Image.Mic)!
    let replay = UIImage(named: Image.Speaker)!
    let mute = UIImage(named: Image.Mute)!
    let stop = UIImage(named: Image.Stop)!
    let chart = UIImage(named: Image.Update)!
    let reset = UIImage(named: Image.Reset)!
    
    // MARK: - View Lifecycle Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // load speech
        speaker = AVSpeechSynthesizer()
        
        // Load initial prompts
        updatePrompts()
        
        txtReply.delegate = self
        txtReply.textColor = .lightGray
        txtReply.text = "tap microphone to respond to prompt"
        
        // Setup Button Taps
        
        let replayTap = UITapGestureRecognizer(target: self, action: #selector(speakTextTapped(_:)))
        replayTap.numberOfTapsRequired = 1
        replayTap.numberOfTouchesRequired = 1
        btnReplay.addGestureRecognizer(replayTap)
        btnReplay.isUserInteractionEnabled = true
        
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
        
        // set speech model delegate so we can get responses from voice recognition
        speechModel.delegate = self
    }
    
    // load navigation bar items
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.navigationItem.title = "Concrete Training"
        let info = UIBarButtonItem(image: UIImage(named: Image.Info), style: .plain, target: self, action: #selector(infoButtonTapped))
        tabBarController?.navigationItem.rightBarButtonItem = info
        
        do {
            try audioSession.setActive(true)
            startObservingVolumeChanges()
        }
        catch {
            print("~>Failed to activate audio session")
        }
    }
    
    // Make sure speech is not going on when leaving the view
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if speaker.isSpeaking { speaker.stopSpeaking(at: .immediate) }
        audioSession.removeObserver(self, forKeyPath: Observation.VolumeKey)
    }
    
    // MARK: - UI Setup Functions
    private func updatePrompts() {
        
        // TODO: - Update to get rid of theysaid verbiage
        guard let prompt = trainingViewModel.getRandomWordPrompt() else { return }
        UIView.animate(withDuration: 0.25, animations: {
            self.lblWord.alpha = 0
            self.txtReply.textColor = .lightGray
            self.txtReply.text = "tap microphone to respond to prompt"
        }) { (_) in
            let word = prompt.word
            self.lblWord.text = "\(word.capitalizedFirst)"
            self.lblWord.alpha = 1.0
            self.view.layoutIfNeeded()
            self.speakTextTapped(self)
        }
    }
    
    
    // MARK: - Button Handling
    
    @IBAction func speakTextTapped(_ sender: Any) {
        DispatchQueue.main.async {
            guard let phrase = self.lblWord.text else { return }
            if self.speaker.isSpeaking { self.speaker.stopSpeaking(at: .immediate) }
            let utterance = AVSpeechUtterance(string: phrase)
            self.speaker.speak(utterance)
        }
    }
    
    @IBAction func recordButtonTapped(_ sender: Any) {
        print("~>Record button tapped.")
        if speechModel.isRecording() {
            speechModel.stopRecording()
            animate(button: btnRecordStop, toImage: mic)
            
            return
        }
        
        speechModel.checkAuthorization { (authorized) in
            if authorized && self.speechModel.isAvailable() {
                if self.speaker.isSpeaking { self.speaker.stopSpeaking(at: .immediate) }
                self.speechModel.startRecording()
                self.animate(button: self.btnRecordStop, toImage: self.stop)
            } else {
                let alert = UIAlertController(title: "Not Available", message: "Speech recogniztion is not currently available.  Please check your internet connection and try again.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    // Score or Load New Prompts
    @IBAction func scoreLoadButtonTapped(_ sender: Any) {
        
        // make sure recording has ended first
        if speechModel.isRecording() {
            speechModel.stopRecording()
            animate(button: btnRecordStop, toImage: mic)
        }
        
        if !shouldReset, let text = txtReply.text {
            if text == "tap microphone to respond to prompt" || text.isEmpty {
                let alert = UIAlertController(title: "Tap Microphone", message: "You must record a response before you can score it.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                present(alert, animated: true, completion: nil)
                return
            }
            
            trainingViewModel.score(response: text)
            tableView.reloadData()
            shouldReset = true
            animate(button: btnScoreReset, toImage: reset)
        } else {
            updatePrompts()
            shouldReset = false
            animate(button: btnScoreReset, toImage: chart)
        }
        
    }
    
    // MARK: - Private Helper Functions
    
    @objc private func infoButtonTapped() {
        print("~>Info button tapped.")
    }
    
    // Volume change helpers
    
    func startObservingVolumeChanges() {
        audioSession.addObserver(self, forKeyPath: Observation.VolumeKey, options: [.initial ,.new], context: &Observation.Context)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "outputVolume"{
            let volume = (change?[NSKeyValueChangeKey.newKey] as!
                NSNumber).floatValue
            print("~>volume " + volume.description)
            if volume == 0.0 && !volumeWasZero {
                animate(button: btnReplay, toImage: mute)
                volumeWasZero = true
            } else if volume != 0 && volumeWasZero {
                animate(button: btnReplay, toImage: replay)
                volumeWasZero = false
            }
        }
    }
    
    // Animation Helpers
    
    private func animate(button: UIImageView, toImage image: UIImage) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.25, animations: {
                button.alpha = 0
            }) { (_) in
                button.image = image
                UIView.animate(withDuration: 0.25, animations: {
                    button.alpha = 1.0
                })
            }
        }
    }
    
}

// MARK: - Table View Delegate Functions

extension ConcreteChatViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 8
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellID.ScaleBar, for: indexPath) as! ScaleBarTableViewCell
        cell.scaleBar.labelType = .IntValue
        
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
        
        setupPopover(for: cell)
        return cell
    }
    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: false)
//        if let cell = tableView.cellForRow(at: indexPath) as? ScaleBarTableViewCell {
//            setupPopover(for: cell)
//        }
//    }
    
    private func getX(for bar: ScaleBar) -> CGFloat {
        let value = CGFloat(bar.calculatedValue)
        return bar.bounds.width * value
    }
    
    private func setupPopover(for cell: ScaleBarTableViewCell) {
        let text = cell.scaleBar.labelText
        let frame = CGRect(x: getX(for: cell.scaleBar), y: cell.scaleBar.frame.origin.y - ((20 - cell.scaleBar.frame.height) / 2), width: 56, height: 20)
        
        if cell.popoverView == nil {
            cell.popoverView = LabelBubbleView(frame: frame, withText: text)
            cell.addSubview(cell.popoverView)
            cell.bringSubviewToFront(cell.popoverView)
        } else {
            cell.popoverView.updateLabel(withText: text, frame: frame)
        }
        
        // adjust frame if needed
        if cell.popoverView.frame.maxX >= cell.scaleBar.frame.maxX {
            cell.popoverView.frame.origin.x -= cell.popoverView.frame.maxX - cell.scaleBar.frame.maxX
        }
        
        if cell.popoverView.frame.minX <= cell.scaleBar.frame.minX {
            cell.popoverView.frame.origin.x += cell.scaleBar.frame.minX - cell.popoverView.frame.minX
        }
    }
}

// MARK: - Speech Task Delegate

extension ConcreteChatViewController: SpeechRecognitionDelegate {
    
    func speechRecognizerGotText(text: String) {
        txtReply.textColor = .black
        txtReply.text = text
    }
    
}

// MARK: - TextView Delegate

extension ConcreteChatViewController: UITextViewDelegate {
    
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
