//
//  PracticeVideoViewController.swift
//  Charm
//
//  Created by Игорь on 19.0520..
//  Copyright © 2020 Charm, LLC. All rights reserved.
//

import UIKit
import AVKit

class PracticeVideoViewController: UIViewController {
    
    enum Phase: String {
        case video = "", start = "Start", recording = "Stop", pendingSubmit = "Submit", scored = "Next"
    }
    
    enum VideoType {
        case question
        case answer
    }
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var checkmarkView: CheckmarkView!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var promptLabel: UILabel!
    @IBOutlet weak var promptExampleLabel: UILabel!
    @IBOutlet weak var siriWaveView: SiriWaveView!
    @IBOutlet weak var userTextLabel: UILabel!
    @IBOutlet weak var stateButton: UIButton!
    @IBOutlet weak var answerTextView: UIView!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var tryAgainButton: UIButton!
    @IBOutlet weak var hintLabel: UILabel!
    
    // MARK: - Properties
    
    var currentVideoType: PracticeVideo.PracticeVideoType = .question {
        didSet {
            
        }
    }
    
    var phase: Phase = .video {
        didSet {
            updateUI()
        }
    }
    
    var partner: PracticePartner!
    var player: AVPlayer?
    var videoLayer: AVPlayerLayer?
    
    private var timer: Timer?
    
    private var questionVideo: PracticeVideo?
    private var answerVideo: PracticeVideo?
    
    fileprivate let viewModel: ConversationManager = ConversationManager.shared
    fileprivate let speechModel: SpeechRecognitionModel = SpeechRecognitionModel()
    
    // For speaking text
    let audioSession = AVAudioSession.sharedInstance()
    var currentPhrase: String = "" {
        didSet {
            userTextLabel.text = currentPhrase
        }
    }
    
    // for tracking current question
    var promptType: PhraseType!
    
    var completedVideoIDS: [String] {
        get {
            let defaults = UserDefaults.standard
            return defaults.value(forKey: "completedVideoIDS") as? [String] ?? []
        }
        
        set {
            let defaults = UserDefaults.standard
            var ids = defaults.value(forKey: "completedVideoIDS") as? [String] ?? []
            ids.append(contentsOf: newValue)
            defaults.set(ids, forKey: "completedVideoIDS")
        }
    }
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        NotificationCenter.default.addObserver(
               self,
               selector: #selector(videoEnded),
               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
               object: nil)
        super.viewDidLoad()
        initialSetup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playback)
            try audioSession.setMode(.moviePlayback)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            // handle errors
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if getNextVideos() {
            nextStep()
        } else {
           showNoVideosAlert()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player?.pause()
        player = nil
        videoLayer?.removeFromSuperlayer()
        videoLayer = nil
        timer?.invalidate()
        timer = nil
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    
    // MARK: - IBActions
    
    @IBAction func tryAgain(_ sender: UIButton) {
        currentPhrase = ""
        phase = .start
    }
    
    @IBAction func changeState(_ sender: UIButton) {
        switch phase {
        case .video:
            stateButton.isHidden = true
            answerTextView.isHidden = true
            checkmarkView.isHidden = true
            resultLabel.isHidden = true
            siriWaveView.isHidden = true
            tryAgainButton.isHidden = true
        case .start:
            speechModel.checkAuthorization { (authorized) in
                DispatchQueue.main.async { [weak self] in
                    guard let strongSelf = self else {
                        return
                    }
                    
                    if authorized && strongSelf.speechModel.isAvailable() {
                        strongSelf.phase = .recording
                        strongSelf.currentPhrase = ""
                        strongSelf.speechModel.startRecording()
                        strongSelf.startTimer()
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
            answerTextView.isHidden = false
            checkmarkView.isHidden = false
            checkmarkView.animate(checked: !checkmarkView.boolValue)
            checkmarkView.isSpinning = true
            viewModel.getScore(for: PhraseInfo(phrase: currentPhrase, type: promptType)) { [weak self] (score) in
                guard let self = self else { return }
                self.update(score: score)
            }
        case .scored:
            phase = .video
            switch currentVideoType {
            case .question:
                currentVideoType = .answer
                if let v = questionVideo {
                    completedVideoIDS = [v.id]
                }
                nextStep()
            case .answer:
                currentVideoType = .question
                if let v = answerVideo {
                    completedVideoIDS = [v.id]
                }
                if getNextVideos() {
                    nextStep()
                } else {
                  showNoVideosAlert()
                }
            }
        }
    }
    
    @IBAction func close(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Methods
    
    private func initialSetup() {
        viewModel.delegate = self
        speechModel.delegate = self
        
        stateButton.isHidden = true
        answerTextView.isHidden = true
        checkmarkView.isHidden = true
        siriWaveView.isHidden = true
        hintLabel.isHidden = true
        tryAgainButton.isHidden = true
        resultLabel.isHidden = true
        
        progressBar.progress = Float(viewModel.progress)
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(stopListening))
        recognizer.numberOfTapsRequired = 1
        siriWaveView.addGestureRecognizer(recognizer)
    }
    
    @objc private func stopListening() {
        stopTimer()
        speechModel.stopRecording()
    }
    
    @objc private func videoEnded() {
        phase = .start
    }
    
    func updateUI() {
        switch phase {
        case .video:
            stateButton.isHidden = true
            answerTextView.isHidden = true
            checkmarkView.isHidden = true
            siriWaveView.isHidden = true
            hintLabel.isHidden = true
            tryAgainButton.isHidden = true
            
        case .start:
            UIView.animate(withDuration: 0.25) {
                self.stateButton.setTitle("Start", for: .normal)
            }
            stateButton.isHidden = false
            answerTextView.isHidden = true
            //            checkmarkView.isHidden = true
            tryAgainButton.isHidden = true
            resultLabel.isHidden = false
            
        case .recording:
            UIView.animate(withDuration: 0.25) {
                self.stateButton.setTitle("Stop", for: .normal)
            }
            answerTextView.isHidden = false
            stateButton.isHidden = true
            tryAgainButton.isHidden = true
            checkmarkView.isHidden = true
            resultLabel.isHidden = true
            
        case .pendingSubmit:
            UIView.animate(withDuration: 0.25) {
                self.stateButton.setTitle("Check", for: .normal)
            }
            stateButton.isHidden = false
            answerTextView.isHidden = false
            tryAgainButton.isHidden = true
            checkmarkView.isHidden = true
            resultLabel.isHidden = true
            
        case .scored:
            UIView.animate(withDuration: 0.25) {
                self.stateButton.setTitle("Next", for: .normal)
            }
            stateButton.isHidden = false
            answerTextView.isHidden = true
            tryAgainButton.isHidden = true
            resultLabel.isHidden = false
      //      checkmarkView.isHidden = true
        }
    }
    
    
    private func nextStep() {
        switch currentVideoType {
        case .question:
            if let v = questionVideo {
                updatePrompt()
                initializeVideoPlayerWithVideo(videoURL: v.url)
            }
        case .answer:
            if let v = answerVideo {
                updatePrompt()
                initializeVideoPlayerWithVideo(videoURL: v.url)
            }
        }
    }
    
    private func getNextVideos() -> Bool {
        let videos = partner.videos.filter { (video) -> Bool in
            return !completedVideoIDS.contains(video.id)
        }
        
        let v1 = videos.randomElement()
        let v2 = videos.first(where: {$0.id == v1?.id && $0.type != v1?.type})
        answerVideo = nil
        questionVideo = nil
        
        if let firstVideo = v1, let secondVideo = v2 {
            for v in [firstVideo, secondVideo] {
                if v.type == .answer {
                    answerVideo = v
                } else if v.type == .question {
                    questionVideo = v
                }
            }
            return true
        }
        
        return false
    }
    
    private func initializeVideoPlayerWithVideo(videoURL: URL) {
        if player != nil, videoLayer != nil {
            checkmarkView.isHidden = false
            checkmarkView.animate(checked: !checkmarkView.boolValue)
            checkmarkView.isSpinning = true
            player?.replaceCurrentItem(with: AVPlayerItem(url: videoURL))
            player?.play()
            return
        }

        // initialize the video player with the url
        let item = AVPlayerItem(url: videoURL)
        self.player = AVPlayer(playerItem: item)
        self.player!.actionAtItemEnd = .pause

        checkmarkView.isHidden = false
        checkmarkView.animate(checked: !checkmarkView.boolValue)
        checkmarkView.isSpinning = true
        self.player?.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 600), queue: DispatchQueue.main, using: { [weak self] time in

              if self?.player?.currentItem?.status == AVPlayerItem.Status.readyToPlay {

                  if let _ = self?.player?.currentItem?.isPlaybackLikelyToKeepUp {
                    self?.checkmarkView.isSpinning = false
                    self?.checkmarkView.isHidden = true
                  }
              }
          })

        videoLayer = AVPlayerLayer(player: player)
        videoLayer!.frame = videoView.bounds
        videoLayer!.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        videoView.layer.addSublayer(videoLayer!)
        
        player!.play()
    }
    
    private func update(score: PhraseScore) {
     //   update(label: lblDetailResponse, withText: score.feedback, usingFont: UIFont.systemFont(ofSize: 16))
        switch score.status {
        case .complete:
            // handle complete
            checkmarkView.isGood = true
            checkmarkView.isSpinning = false
            viewModel.add(experience: 2)
            phase = .scored
        case .incomplete:
            checkmarkView.isGood = false
            checkmarkView.isSpinning = false
            viewModel.add(experience: -1)
            phase = .start
        }
        resultLabel.text = score.feedback
        checkmarkView.animate(checked: checkmarkView.isGood)
    }
    
    // MARK: - Siri Wave
    
    @objc func updateMeters() {
        var normalizedValue: Float
        normalizedValue = Float(speechModel.normalizedPowerLevelFromDecibels)
        self.siriWaveView.update(CGFloat(normalizedValue) * 100)
    }
    
    private func startTimer() {
        siriWaveView.isHidden = false
        hintLabel.isHidden = false
        stateButton.isHidden = true
        answerTextView.isHidden = false
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.10, repeats: true) { [weak self] (Timer) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.updateMeters()
        }
    }
    
    private func stopTimer() {
        siriWaveView.isHidden = true
        hintLabel.isHidden = true
        
        if timer != nil {
            timer?.invalidate()
        }
        timer = nil
    }
    
    fileprivate func updatePrompt() {
        promptType = viewModel.getType(video: currentVideoType)
        
        var labelText: String = ""
        var labelExampleText: String = ""
        switch promptType {
        case .specific:
            labelText = "Say Something concrete"
            labelExampleText = "For example: duck, train, David"
        case .connection:
            labelText = "Say something about \"you and me\""
            labelExampleText = "For example: I like you… I think you…. You are like me…"
        case .positive:
            labelText = "Say Something Positive"
            labelExampleText = "For example: love, hope, excited"
        case .negative:
            labelText = "Say something Negative"
            labelExampleText = "For example: bad, terrible, sad"
        case .none:
            break
        }
        resultLabel.text = ""
        promptLabel.text = labelText
        promptExampleLabel.text = labelExampleText
    }
    
    // MARK: - Recognition
    
    fileprivate func showUserReply() {
        stopTimer()
        speechModel.stopRecording()
        phase = .pendingSubmit
    }
    
    fileprivate func showEmptyAlert() {
        stopTimer()
        speechModel.stopRecording()
        let alert = UIAlertController(title: "Try Again", message: "We were unable to detect your speech.  Please try again.", preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "Ok", style: .default, handler: { (_) in
            self.phase = .start
        }))
        present(alert, animated: true, completion: nil)
    }
    
    fileprivate func showNoVideosAlert() {
        let alert = UIAlertController(title: "All videos with this partner completed!", message: "Choose another partner or work again with this partner.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Choose another", style: .default, handler: { (_) in
            self.dismiss(animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Keep this partner", style: .default, handler: { (_) in
            self.resetVideoForParntner()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    
    private func resetVideoForParntner() {
        let defaults = UserDefaults.standard
        var ids = defaults.value(forKey: "completedVideoIDS") as? [String] ?? []
        for video in partner.videos {
            ids.removeAll { (id) -> Bool in
                return id == video.id
            }
        }
        defaults.setValue(ids, forKey: "completedVideoIDS")

        phase = .video
        if getNextVideos() {
            nextStep()
        }
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

    }

    
}

// MARK: - Recognition


extension PracticeVideoViewController: SpeechRecognitionDelegate {
    func speechRecognizerGotText(text: String) {
        currentPhrase = text
    }
    
    func speechRecognizerFinished(successfully: Bool) {
        currentPhrase.isEmpty ? showEmptyAlert() : showUserReply()
    }
}

// MARK: - Level

extension PracticeVideoViewController: LevelUpDelegate {
    func updated(progress: Double) {
        progressBar.progress = Float(progress)
    }
    
    func updated(level: Int, detail: String, progress: Double) {
        progressBar.progress = Float(progress)
    }
}
