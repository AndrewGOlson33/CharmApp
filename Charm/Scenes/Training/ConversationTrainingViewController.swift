//
//  ConversationTrainingViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 3/22/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit
import Speech
import AVKit
import Firebase

class ConversationTrainingViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    // Views
    @IBOutlet weak var viewFeedback: UIView!
    @IBOutlet weak var viewTopChat: UIView!
    @IBOutlet weak var viewBottomChat: UIView!
    @IBOutlet weak var viewSlider: SliderView!
    
    // Text
    
    @IBOutlet weak var lblTopChat: UILabel!
    @IBOutlet weak var lblBottomChat: UILabel!
    @IBOutlet weak var txtReply: UITextView!
    @IBOutlet weak var lblScore: UILabel!
    @IBOutlet weak var lblFeedback: UILabel!
    
    // buttons
    
//    @IBOutlet weak var btnReplay: UIImageView!
    @IBOutlet weak var btnReplay: UIButton!
    @IBOutlet weak var btnRecordStop: UIButton!
    @IBOutlet weak var btnScoreReset: UIButton!
//    @IBOutlet weak var btnRecordStop: UIImageView!
//    @IBOutlet weak var btnScoreReset: UIImageView!
    
    // Layout constraints
    @IBOutlet weak var youSaidOnTop: NSLayoutConstraint!
    @IBOutlet weak var theySaidOnTop: NSLayoutConstraint!
    
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
    
    let mic = UIImage(named: Image.mic)!
    let replay = UIImage(named: Image.speaker)!
    let mute = UIImage(named: Image.mute)!
    let stop = UIImage(named: Image.stop)!
    let chart = UIImage(named: Image.update)!
    let reset = UIImage(named: Image.reset)!
    
    // MARK: - View Lifecycle Functions

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // load speech
        speaker = AVSpeechSynthesizer()

        txtReply.delegate = self
        txtReply.textColor = .lightGray
        txtReply.text = "tap microphone to respond to prompt"
        
        // Prepare slider for setup
        viewSlider.alpha = 0.0
        
        // Setup Button Taps

//        let replayTap = UITapGestureRecognizer(target: self, action: #selector(speakTextTapped(_:)))
//        replayTap.numberOfTapsRequired = 1
//        replayTap.numberOfTouchesRequired = 1
//        btnReplay.addGestureRecognizer(replayTap)
//        btnReplay.isUserInteractionEnabled = true
//
//        let recordStopTap = UITapGestureRecognizer(target: self, action: #selector(recordButtonTapped(_:)))
//        recordStopTap.numberOfTapsRequired = 1
//        recordStopTap.numberOfTouchesRequired = 1
//        btnRecordStop.addGestureRecognizer(recordStopTap)
//        btnRecordStop.isUserInteractionEnabled = true
//
//        let scoreResetTap = UITapGestureRecognizer(target: self, action: #selector(scoreLoadButtonTapped(_:)))
//        scoreResetTap.numberOfTapsRequired = 1
//        scoreResetTap.numberOfTouchesRequired = 1
//        btnScoreReset.addGestureRecognizer(scoreResetTap)
//        btnScoreReset.isUserInteractionEnabled = true
        
        // set speech model delegate so we can get responses from voice recognition
        speechModel.delegate = self
        
        // setup ui elements
        viewFeedback.layer.borderColor = #colorLiteral(red: 0.830419898, green: 0.835508287, blue: 0.835278213, alpha: 1)
        viewFeedback.layer.borderWidth = 1.0
        viewFeedback.layer.cornerRadius = 16
        txtReply.layer.cornerRadius = 16
        txtReply.layer.masksToBounds = true
//        txtReply.backgroundColor = UIColor.
        // setup prompt bubbles
        viewTopChat.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMinYCorner]
        viewBottomChat.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMinXMinYCorner]
        
        viewTopChat.layer.cornerRadius = 16
        viewBottomChat.layer.cornerRadius = 16
        
        // Load initial prompts
        updatePrompts()
    }
    
    // load navigation bar items
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.navigationItem.title = "Practice with Topic"
        let info = UIBarButtonItem(title: "Learn More", style: .plain, target: self, action: #selector(infoButtonTapped))
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        updateFeedbackResponses()
        UIView.animate(withDuration: 0.5) {
            self.viewSlider.alpha = 1.0
        }
    }
    
    // MARK: - UI Setup Functions
    private func updatePrompts() {
        guard let prompt = trainingViewModel.getRandomConversationPrompt() else { return }
        UIView.animate(withDuration: 0.25, animations: {
            self.viewTopChat.alpha = 0.0
            self.viewBottomChat.alpha = 0.0
            self.txtReply.textColor = .lightGray
            self.txtReply.text = "tap microphone to respond to prompt"
            self.txtReply.isUserInteractionEnabled = true
            self.lblFeedback.text = "Comments:\nYour feedback will appear here."
            if self.viewSlider.isSetup {
                self.viewSlider.updatePosition(to: 0.0)
            }
        }) { (_) in
            let promptString = prompt.prompt
            self.lblTopChat.text = "\(promptString)"
            UIView.animate(withDuration: 0.25, animations: {
                self.viewTopChat.alpha = 1.0
            })
            
            self.speakTextTapped(self)
        }
    }
    
    // MARK: - Button Handling
    
    @IBAction func speakTextTapped(_ sender: Any) {
        DispatchQueue.main.async {
            guard let prompt = self.lblTopChat.text else { return }
            if self.speaker.isSpeaking { self.speaker.stopSpeaking(at: .immediate) }
            let utterance = AVSpeechUtterance(string: prompt)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
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
            txtReply.isUserInteractionEnabled = false
            let replyText = txtReply.text
            lblBottomChat.text = replyText
            txtReply.text = ""
            
            UIView.animate(withDuration: 0.25) {
                self.viewBottomChat.alpha = 1.0
            }
            
            shouldReset = true
            animate(button: btnScoreReset, toImage: reset)
            updateFeedbackResponses()
        } else {
            updatePrompts()
            shouldReset = false
            animate(button: btnScoreReset, toImage: chart)
        }
    }
    
    // MARK: - Private Helper Functions
    
    @objc private func infoButtonTapped() {
        guard let info = storyboard?.instantiateViewController(withIdentifier: StoryboardID.info) as? InfoDetailViewController else { return }
        info.type = .conversation
        tabBarController?.navigationController?.pushViewController(info, animated: true)
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
    
    private func animate(button: UIButton, toImage image: UIImage) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.25, animations: {
                button.alpha = 0
            }) { (_) in
                button.setImage(image, for: .normal)
                UIView.animate(withDuration: 0.25, animations: {
                    button.alpha = 1.0
                })
            }
        }
    }
    
    private func updateFeedbackResponses() {
        let strength = trainingViewModel.strength
        
        DispatchQueue.main.async {
            if !self.viewSlider.isSetup {
                self.viewSlider.setup(for: .standard, atPosition: CGFloat(strength.position), color: #colorLiteral(red: 0.4862745098, green: 0.7098039216, blue: 0.9254901961, alpha: 1))
            } else {
                self.viewSlider.updatePosition(to:  CGFloat(strength.position))
                UIView.animate(withDuration: 0.2, animations: {
                    self.lblScore.alpha = 0.0
                    self.lblFeedback.alpha = 0.0
                }, completion: { (_) in
                    self.lblScore.text = "\(strength.score)/10"
                    self.lblFeedback.text = self.trainingViewModel.feedback
                    UIView.animate(withDuration: 0.2, animations: {
                        self.lblScore.alpha = 1.0
                        self.lblFeedback.alpha = 1.0
                        self.view.layoutIfNeeded()
                    })
                })
            }
        }
    }
}

// MARK: - Table View Delegate Functions

extension ConversationTrainingViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 8
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellID.scaleBar, for: indexPath) as! ScaleBarTableViewCell
        
        switch indexPath.row {
        case 0:
            let strength = trainingViewModel.strength
            cell.lblDescription.text = "Phrase Strength"
            cell.lblScore.text = "\(strength.score)"
            cell.sliderView.progress = Float(strength.position)
        case 1:
            let length = trainingViewModel.length
            cell.lblDescription.text = "Phrase Length"
            cell.lblScore.text = "\(length.score)"
            cell.sliderView.progress = Float(length.position)
        case 2:
            let concrete = trainingViewModel.concrete
            cell.lblDescription.text = "Concrete Details"
            cell.lblScore.text = "\(concrete.score)"
            cell.sliderView.progress = Float(concrete.position)
        case 3:
            let abstract = trainingViewModel.abstract
            cell.lblDescription.text = "Abstract Ideas"
            cell.lblScore.text = "\(abstract.score)"
            cell.sliderView.progress = Float(abstract.position)
        case 4:
            let first = trainingViewModel.first
            cell.lblDescription.text = "First Person (\"I/\"Me\")"
            cell.lblScore.text = "\(first.score)"
            cell.sliderView.progress = Float(first.position)
        case 5:
            let second = trainingViewModel.second
            cell.lblDescription.text = "Second Person (\"You\")"
            cell.lblScore.text = "\(second.score)"
            cell.sliderView.progress = Float(second.position)
        case 6:
            let positive = trainingViewModel.positive
            cell.lblDescription.text = "Positive Word Score"
            cell.lblScore.text = "\(positive.score)"
            cell.sliderView.progress = Float(positive.position)
        case 7:
            let negative = trainingViewModel.negative
            cell.lblDescription.text = "Negative Word Score"
            cell.lblScore.text = "\(negative.score)"
            cell.sliderView.progress = Float(negative.position)
        default:
            print("~>Should not be possible to get here.")
        }
        
        return cell
    }
}

// MARK: - Speech Task Delegate

extension ConversationTrainingViewController: SpeechRecognitionDelegate {
    
    func speechRecognizerFinished(successfully: Bool) {
        if !successfully { print("~>Not a success") }
    }
    
    func speechRecognizerGotText(text: String) {
        txtReply.textColor = .black
        txtReply.text = text
    }
}

// MARK: - TextView Delegate

extension ConversationTrainingViewController: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if #available(iOS 13.0, *) {
            textView.textColor = .label
        } else {
            textView.textColor = .black
        }
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
