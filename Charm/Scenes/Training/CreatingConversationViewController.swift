//
//  CreatingConversationViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 2/3/20.
//  Copyright © 2020 Charm, LLC. All rights reserved.
//

import UIKit
import AVKit
import PXSiriWave

class CreatingConversationViewController: UIViewController {
    
    enum Phase: String {
        case start = "Start", recording = "Stop", pendingSubmit = "Submit", scored = "Next"
    }

    // MARK: - IBOutlets
    
    @IBOutlet weak var lblLevelInfo: UILabel!
    @IBOutlet weak var progressSlider: SliderView!
    @IBOutlet weak var lblProgress: UILabel!
    @IBOutlet weak var lblDetailResponse: UILabel!
    @IBOutlet weak var promptBubble: UIView!
    @IBOutlet weak var replyBubble: UIView!
    @IBOutlet weak var lblPrompt: UILabel!
    @IBOutlet weak var lblReply: UILabel!
    @IBOutlet weak var txtUserResponse: UITextView!
    @IBOutlet weak var buttonView: UIControl!
    @IBOutlet weak var lblButtonTitle: UILabel!
    @IBOutlet weak var buttonActivityView: UIActivityIndicatorView!
    @IBOutlet weak var buttonImage: UIImageView!
    @IBOutlet weak var loadingActivityView: UIActivityIndicatorView!
    @IBOutlet weak var siriWave: PXSiriWave!

    // MARK: - Properties
    
    fileprivate let viewModel: CreatingConversationViewModel = CreatingConversationViewModel()
    fileprivate let speechModel: SpeechRecognitionModel = SpeechRecognitionModel()
    
    private var timer: Timer?
    
    // for tracking current question
    var prompt: PhraseInfo!
    
    // for tracking phase
    var phase: Phase = .start {
        didSet {
            updateButton()
        }
    }
    
    var currentImage: UIImage {
        switch phase {
        case .start:
            return UIImage(named: "icn_mic")!
        case .recording:
            return UIImage(named: "icn_stop")!
        case .pendingSubmit:
            return UIImage(named: "icn_update")!
        case .scored:
            return UIImage(named: "icn_next")!
        }
    }
    
    // For speaking text
    var speaker: AVSpeechSynthesizer = AVSpeechSynthesizer()
    let audioSession = AVAudioSession.sharedInstance()
    var volumeWasZero = false
    var currentPhrase: String = ""
    
    private struct Observation {
        static let VolumeKey = "outputVolume"
        static var Context = 0
    }
    
    // MARK: - View Lifecycle Functions

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.delegate = self
        speechModel.delegate = self
        txtUserResponse.delegate = self
        setupUI()
        loadModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self,
                                               selector : #selector(keyboardWillAppear(notification:)),
                                               name     : UIResponder.keyboardWillShowNotification,
                                               object   : nil)
        NotificationCenter.default.addObserver(self,
                                               selector : #selector(keyboardWillDisappear(notification:)),
                                               name     : UIResponder.keyboardWillHideNotification,
                                               object   : nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        print("~>Firebase user uid: ", FirebaseModel.shared.charmUser.id ?? "Undefined")
        
        print("~>Progress: \(viewModel.progress)")
        progressSlider.setup(for: .standard, atPosition: CGFloat(viewModel.progress), color: #colorLiteral(red: 0.4862745098, green: 0.7098039216, blue: 0.9254901961, alpha: 1))
        
        update(label: lblProgress, withText: viewModel.progressText)
        if let levelDetail = viewModel.levelDetail {
            update(label: lblLevelInfo, withText: levelDetail)
        }
        
        UIView.animate(withDuration: 0.5) { [weak self] in
            guard let self = self else { return }
            self.progressSlider.alpha = 1.0
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self,
                                                  name   : UIResponder.keyboardWillShowNotification,
                                                  object : nil)
        NotificationCenter.default.removeObserver(self,
                                                  name   : UIResponder.keyboardWillHideNotification,
                                                  object : nil)
    }
    
    // MARK: - Private Setup Helper
    
    fileprivate func setupUI() {
        // setup button
        buttonView.layer.cornerRadius = 8
        lblButtonTitle.text = phase.rawValue
        
        // setup bubbles
        promptBubble.layer.cornerRadius = 16
        promptBubble.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
        
        replyBubble.layer.cornerRadius = 16
        replyBubble.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMinXMinYCorner]
        
        // Stup SiriWave
        siriWave.isHidden = true
        
        siriWave.frequency = 1.5
        siriWave.amplitude = 0.01
        siriWave.intensity = 0.3
        siriWave.colors = [UIColor.red, UIColor.blue, UIColor.green]
        siriWave.configure()
    }
    
    fileprivate func loadModel() {
        switch viewModel.loadStatus {
        case .loaded:
            if loadingActivityView.isAnimating { loadingActivityView.stopAnimating() }
            updatePhrase()
        case .loading:
            if !loadingActivityView.isAnimating { loadingActivityView.startAnimating() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                guard let self = self else { return }
                self.loadModel()
            }
        case .failed:
            showFailedLoadAlert()
        }
    }
    
    fileprivate func showFailedLoadAlert() {
        let alert = UIAlertController(title: "Error", message: "Unable to load training phrases.  If your internet is working, please try again later.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] (_) in
            guard let self = self else { return }
            self.navigationController?.popViewController(animated: true)
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - UI Update Functions
    
    @objc
    func keyboardWillAppear(notification: NSNotification?) {

        guard let keyboardFrame = notification?.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }

        let keyboardHeight: CGFloat
        if #available(iOS 11.0, *) {
            keyboardHeight = keyboardFrame.cgRectValue.height - self.view.safeAreaInsets.bottom
        } else {
            keyboardHeight = keyboardFrame.cgRectValue.height
        }

        view.frame.origin.y -= keyboardHeight
    }

    @objc
    func keyboardWillDisappear(notification: NSNotification?) {
        view.frame.origin.y = 0
    }
    
    fileprivate func updatePhrase() {
        prompt = viewModel.getPrompt()
        let promptText = prompt.phrase
        
        let labelText: String
        switch prompt.type {
        case .specific:
            labelText = "Reply With Some Specifics"
        case .connection:
            labelText = "Create a Connection With First and Second Person Words"
        case .positive:
            labelText = "Reply With Some Positive Words"
        case .negative:
            labelText = "Reply Using Some Negative Words"
        }
        
        update(label: lblPrompt, withText: promptText, speakText: true)
        update(label: lblDetailResponse, withText: labelText, usingFont: UIFont.boldSystemFont(ofSize: 18))
        
        if promptBubble.isHidden { show(view: promptBubble) }
        if !replyBubble.isHidden { hide(view: replyBubble) }
        
    }
    
    fileprivate func showUserReply() {
        update(label: lblReply, withText: currentPhrase)
        show(view: replyBubble)
        txtUserResponse.text = currentPhrase
        show(view: txtUserResponse)
    }
    
    fileprivate func showEmptyAlert() {
        let alert = UIAlertController(title: "Try Again", message: "We were unable to detect your speech.  Please try again.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Type", style: .cancel, handler: { [weak self] (_) in
            guard let self = self else { return }
            self.phase = .pendingSubmit
            self.txtUserResponse.isHidden = false
        }))
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    fileprivate func hide(view: UIView) {
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            guard self != nil else { return }
            view.alpha = 0.0
            view.isHidden = false
        }) { [weak self] (_) in
            guard self != nil else { return }
            view.isHidden = true
        }
    }
    
    fileprivate func show(view: UIView) {
        view.alpha = 0.0
        view.isHidden = false
        UIView.animate(withDuration: 0.5) { [weak self] in
            guard self != nil else { return }
            view.alpha = 1.0
        }
    }
    
    fileprivate func update(label: UILabel, withText text: String, usingFont font: UIFont? = nil, speakText: Bool = false) {
        if label.isHidden { label.isHidden = false }
        
        UIView.animate(withDuration: 0.1, animations: { [weak self] in
            guard self != nil else { return }
            label.alpha = 0.0
            if let font = font { label.font = font }
        }) { [weak self] (_) in
            guard self != nil else { return }
            label.text = text
            UIView.animate(withDuration: 0.1, animations: { [weak self] in
                guard self != nil else { return }
                label.alpha = 1.0
            }) { [weak self] _ in
                guard let self = self, speakText else { return }
                let utterance = AVSpeechUtterance(string: text)
                self.speaker.speak(utterance)
            }
        }
    }
    
    fileprivate func updateReplyLabel(with text: NSAttributedString) {
        UIView.animate(withDuration: 0.1, animations: { [weak self] in
            guard let self = self else { return }
            self.lblReply.alpha = 0.5
        }) { [weak self] (_) in
            guard let self = self else { return }
            self.lblReply.attributedText = text
            UIView.animate(withDuration: 0.1) { [weak self] in
                guard let self = self else { return }
                self.lblReply.alpha = 1.0
            }
        }
    }
    
    fileprivate func updateButtonImage() {
        UIView.animate(withDuration: 0.15, animations: { [weak self] in
            guard let self = self else { return }
            self.buttonImage.alpha = 0.0
        }) { [weak self] (_) in
            guard let self = self else { return }
            self.buttonImage.image = self.currentImage
            UIView.animate(withDuration: 0.17) { [weak self] in
                guard let self = self else { return }
                self.buttonImage.alpha = 0.2
            }
        }
    }
    
    fileprivate func updateButton() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.update(label: self.lblButtonTitle, withText: self.phase.rawValue)
            self.updateButtonImage()
        }
    }
    
    // MARK: - Button Handling
    
    @IBAction func buttonTouchedDown(_ sender: Any) {
        enableButtonPressedUI()
    }
    
    @IBAction func buttonTouchUpOutside(_ sender: Any) {
        disableButtonPressedUI()
    }
    
    @IBAction func buttonTouchUpInside(_ sender: Any) {
        disableButtonPressedUI()
        
        // handle button action
        switch phase {
        case .start:
            speechModel.checkAuthorization { (authorized) in
                DispatchQueue.main.async { [weak self] in
                    guard let strongSelf = self else {
                        return
                    }
                    
                    if authorized && strongSelf.speechModel.isAvailable() {
                        
                        strongSelf.currentPhrase = ""
                        strongSelf.speechModel.startRecording()
                        strongSelf.startTimer()
//                        strongSelf.loadingActivityView.startAnimating()
                        strongSelf.phase = .recording
                    } else {
                        let alert = UIAlertController(title: "Not Available", message: "Speech recognition is currently unavailable or access is restricted. Please check your Internet connection, Speech Recognition permissions in the Settings and try again.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { (UIAlertAction) in
                            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                                return
                            }
                            
                            if UIApplication.shared.canOpenURL(settingsUrl) {
                                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                                    print("~> Settings opened: \(success)")
                                })
                            }
                        }))
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        strongSelf.present(alert, animated: true, completion: nil)
                    }
                }
            }
        case .recording:
            stopTimer()
            speechModel.stopRecording()
        case .pendingSubmit:
            self.view.endEditing(true)
            
            self.txtUserResponse.isHidden = true
            
            self.buttonActivityView.startAnimating()
            viewModel.getScore(for: PhraseInfo(phrase: currentPhrase, type: prompt.type)) { [weak self] (score) in
                guard let self = self else { return }
                self.handle(score: score)
            }
        case .scored:
            phase = .start
            updatePhrase()
        }
    }
    
    // MARK: Siri Wave
    
    private func startTimer() {
        siriWave.isHidden = false
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.10, repeats: true) { [weak self] (Timer) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.siriWave.update(withLevel: strongSelf.speechModel.normalizedPowerLevelFromDecibels)
        }
    }
    
    private func stopTimer() {
        siriWave.isHidden = true
        
        if timer != nil {
            timer?.invalidate()
        }
        timer = nil
    }
    
    // MARK: - Score Helper
    
    fileprivate func handle(score: PhraseScore) {
        buttonActivityView.stopAnimating()
        update(label: lblDetailResponse, withText: score.feedback, usingFont: UIFont.systemFont(ofSize: 16))
        
        switch score.status {
        case .complete:
            // handle complete
            updateReplyLabel(with: score.formattedText)
            viewModel.add(experience: 1)
            phase = .scored
        case .incomplete:
            phase = .start
        }
    }
    
    // MARK: - Button Helper Functions
    
    fileprivate func enableButtonPressedUI() {
        buttonView.alpha = 0.6
    }
    
    fileprivate func disableButtonPressedUI() {
        buttonView.alpha = 1.0
    }
}

extension CreatingConversationViewController: LevelUpDelegate {
    
    func updated(progress: Double) {
        lblProgress.text = viewModel.progressText
        progressSlider.updatePosition(to: CGFloat(progress))
    }
    
    func updated(level: Int, detail: String, progress: Double) {
        print("~>This happened.")
        update(label: lblLevelInfo, withText: detail)
        lblProgress.text = viewModel.progressText
        progressSlider.updatePosition(to: CGFloat(progress))
    }
}

extension CreatingConversationViewController: SpeechRecognitionDelegate {
    
    func speechRecognizerGotText(text: String) {
        currentPhrase = text
    }
    
    func speechRecognizerFinished(successfully: Bool) {
//        loadingActivityView.stopAnimating()
        currentPhrase.isEmpty ? showEmptyAlert() : showUserReply(); phase = .pendingSubmit
        if !successfully { print("~>Not a success") }
    }
}

extension CreatingConversationViewController: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        currentPhrase = textView.text
        showUserReply()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            buttonTouchUpInside(self)
            return false
        } else {
            return true
        }
    }
    
}
