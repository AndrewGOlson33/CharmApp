//
//  EmotionFlashcardsViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 4/4/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase
import AVKit

class EmotionFlashcardsViewController: UIViewController {

    // MARK: - IBOutlets
    
    @IBOutlet weak var lblStreak: UILabel!
    @IBOutlet weak var streakBar: SliderView!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var viewFlashcards: UIView!
    @IBOutlet weak var lblWord: UILabel!
    @IBOutlet weak var viewLoading: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var lblResponsePhrase: UILabel!
    
    // button collection (they need borders and shadows)
    @IBOutlet var buttonCollection: [UIView]!
    @IBOutlet weak var btnPositive: UIView!
    @IBOutlet weak var btnNeutral: UIView!
    @IBOutlet weak var btnNegative: UIView!
    
    // button contents
    @IBOutlet weak var lblPositive: UILabel!
    @IBOutlet weak var lblNeutral: UILabel!
    @IBOutlet weak var lblNegative: UILabel!
    
    
    // MARK: - Properties
    
    // View Model
    let viewModel = FlashcardsViewModel()
    
    // View Properties
    
    var positiveFrame: CGRect = CGRect.zero
    var neutralFrame: CGRect = CGRect.zero
    var negativeFrame: CGRect = CGRect.zero
    
    var lastTouchedButton: UIView? = nil
    
    // Popover view
    var popoverView: LabelBubbleView!
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup shadows and corners on flashcard view
        viewFlashcards.layer.cornerRadius = 20
        viewFlashcards.layer.shadowColor = UIColor.black.cgColor
        viewFlashcards.layer.shadowRadius = 2.0
        viewFlashcards.layer.shadowOffset = CGSize(width: 2, height: 2)
        viewFlashcards.layer.shadowOpacity = 0.5
        
        // Setup borders and shadows for buttons
        for button in buttonCollection {
            button.layer.borderColor = UIColor.black.cgColor
            button.layer.borderWidth = 1.0
            button.layer.cornerRadius = button.frame.height / 6
            button.layer.shadowColor = UIColor.black.cgColor
            button.layer.shadowRadius = 2.0
            button.layer.shadowOffset = CGSize(width: 2, height: 2)
            button.layer.shadowOpacity = 0.5
            button.layer.masksToBounds = false
        }
        
        btnPositive.setGradientBackground(colorTop: #colorLiteral(red: 0.2968337834, green: 0.4757083654, blue: 0.2566408515, alpha: 1), colorBottom: #colorLiteral(red: 0.2968337834, green: 0.4757083654, blue: 0.2566408515, alpha: 0.8019049658))
        btnNeutral.setGradientBackground(colorTop: #colorLiteral(red: 0.6313157678, green: 0.6314089298, blue: 0.6312955022, alpha: 1), colorBottom: #colorLiteral(red: 0.6313157678, green: 0.6314089298, blue: 0.6312955022, alpha: 0.8009952911))
        btnNegative.setGradientBackground(colorTop: #colorLiteral(red: 0.7257528305, green: 0.3471282721, blue: 0.3915748596, alpha: 1), colorBottom: #colorLiteral(red: 0.7257528305, green: 0.3471282721, blue: 0.3915748596, alpha: 0.794921875))
        
        streakBar.setup(for: .fillFromLeft)

        viewModel.getAverageEmotionsScore { (emotionsScores) in
            // make sure this is done on main thread
            DispatchQueue.main.async {
                self.lblStreak.text = "Current Streak: \(emotionsScores.numCorrect)"
                self.streakBar.updatePosition(to: CGFloat(emotionsScores.percentOfRecord))
            }
            
        }
        
        // Start animating activity view and turn on firebase listener
        if viewModel.trainingModel.model.positiveWords.count == 0 || viewModel.trainingModel.model.negativeWords.count == 0 || viewModel.trainingModel.model.abstractNouns.count == 0 {
            viewLoading.layer.cornerRadius = 20
            viewLoading.isHidden = false
            activityIndicator.startAnimating()
            NotificationCenter.default.addObserver(self, selector: #selector(firebaseModelLoaded), name: FirebaseNotification.TrainingModelLoaded, object: nil)
        } else {
            firebaseModelLoaded()
        }
        
    }
    
    // load navigation bar items
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.navigationItem.title = "Emotions"
        let info = UIBarButtonItem(image: UIImage(named: Image.Info), style: .plain, target: self, action: #selector(infoButtonTapped))
        tabBarController?.navigationItem.rightBarButtonItem = info
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // set the original frames to use for animations
        positiveFrame = btnPositive.frame
        neutralFrame = btnNeutral.frame
        negativeFrame = btnNegative.frame
        
        // setup listener for when score updates
        NotificationCenter.default.addObserver(self, selector: #selector(trainingHistoryUpdated), name: FirebaseNotification.TrainingHistoryUpdated, object: nil)
    }
    
    // Remove observer when view is not visible
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: FirebaseNotification.TrainingHistoryUpdated, object: nil)
    }
    
    // MARK: - Private Helper Functions
    
    @objc private func infoButtonTapped() {
        let avPlayerVC = AVPlayerViewController()
        avPlayerVC.entersFullScreenWhenPlaybackBegins = true
        let videoStorage = Storage.storage()
        
        // TODO: - update with correct link
        let urlString = "gs://charismaanalytics-57703.appspot.com/learning/fundamentals/SampleVideo_1280x720_2mb.mp4"
        
        videoStorage.reference(forURL: urlString).downloadURL { (url, error) in
            if let url = url {
                let player = AVPlayer(url: url)
                avPlayerVC.player = player
                self.present(avPlayerVC, animated: true, completion: nil)
                // start playing the video as soon as it loads
                avPlayerVC.player?.play()
            } else if let error = error {
                print("~>Unable to get storage url: \(error)")
                return
            } else {
                // this should never happen
                print("~>An unknown error has occured.")
            }
        }
    }
    
    // Get calculated x coord for scalebar
    private func getX(for bar: ScaleBar) -> CGFloat {
        let value = CGFloat(bar.calculatedValue)
        return bar.bounds.width * value
    }
    
    // Setup UI once the firebase model is loaded
    @objc private func firebaseModelLoaded() {
        // remove listener
        NotificationCenter.default.removeObserver(self, name: FirebaseNotification.TrainingModelLoaded, object: nil)
        
        // setup first flashcard
        lblWord.text = viewModel.getFlashCard(ofType: .Emotions).capitalizedFirst
        lblWord.alpha = 0.0
        lblWord.isHidden = false
        
        UIView.animate(withDuration: 0.4, animations: {
            self.lblWord.alpha = 1.0
            self.viewLoading.alpha = 0.0
        }) { (_) in
            self.activityIndicator.stopAnimating()
            self.viewLoading.isHidden = true
        }
        
    }
    
    // Updates UI When Training Data Updates
    
    @objc private func trainingHistoryUpdated() {
        
        viewModel.getAverageEmotionsScore { (newHistory) in
            DispatchQueue.main.async {
                self.lblStreak.text = "Current Streak: \(newHistory.numCorrect)"
                self.streakBar.updatePosition(to: CGFloat(newHistory.percentOfRecord))
            }
        }
        
    }
    
    // Hande Updates After Answer is Submitted
    
    private func handle(response: (response: String, correct: Bool)) {
        animate(responseText: response.response)
        updateScore(withCorrectAnswer: response.correct)
    }
    
    // Updates Score
    private func updateScore(withCorrectAnswer correct: Bool) {
        viewModel.calculateAverageScore(addingCorrect: correct, toType: .Emotions)
        
    }
    
    // Animation Helper Function For Response
    
    private func animate(responseText text: String) {
        lblResponsePhrase.text = text
        lblResponsePhrase.alpha = 0.0
        lblResponsePhrase.isHidden = false
        
        UIView.animate(withDuration: 0.2, animations: {
            self.lblResponsePhrase.alpha = 1.0
        }) { (_) in
            UIView.animate(withDuration: 0.25, delay: 1.5, animations: {
                self.lblResponsePhrase.alpha = 0.0
            }, completion: { (_) in
                self.lblResponsePhrase.isHidden = true
                self.updateFlashcard()
            })
        }
    }
    
    // Animation helper to setup new word
    private func updateFlashcard() {
        let newWord = viewModel.getFlashCard(ofType: .Emotions).capitalizedFirst
        UIView.animate(withDuration: 0.25, delay: 0.25, animations: {
            self.lblWord.alpha = 0.0
        }) { (_) in
            self.lblWord.text = newWord
            UIView.animate(withDuration: 0.4, animations: {
                self.lblWord.alpha = 1.0
            })
        }
    }
    
    // Animation Helper Function For Toggling Buttons
    private func animate(view: UIView, withLabel label: UILabel, withColor color: UIColor, toFrame frame: CGRect) {
        UIView.animate(withDuration: 0.2, animations: {
            view.frame = frame
            label.textColor = color
        })
    }
    
    // MARK: - Button Handling
    
    @IBAction func resetButtonTapped(_ sender: Any) {
        viewModel.resetRecord(forType: .Emotions)
    }
    
}

extension EmotionFlashcardsViewController: UIGestureRecognizerDelegate {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            
            if positiveFrame.contains(touch.location(in: view)) {
                animate(view: btnPositive, withLabel: lblPositive, withColor: .gray, toFrame: CGRect(x: positiveFrame.minX + 4, y: positiveFrame.minY + 4, width: positiveFrame.width, height: positiveFrame.height))
                lastTouchedButton = btnPositive
            } else if neutralFrame.contains(touch.location(in: view)) {
                animate(view: btnNeutral, withLabel: lblNeutral, withColor: .gray, toFrame: CGRect(x: neutralFrame.minX + 4, y: neutralFrame.minY + 4, width: neutralFrame.width, height: neutralFrame.height))
                lastTouchedButton = btnNeutral
            } else if negativeFrame.contains(touch.location(in: view)) {
                animate(view: btnNegative, withLabel: lblNegative, withColor: .gray, toFrame: CGRect(x: negativeFrame.minX + 4, y: negativeFrame.minY + 4, width: negativeFrame.width, height: negativeFrame.height))
                lastTouchedButton = btnNegative
            }
            
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard lastTouchedButton != nil else { return }
        if let touch = touches.first {
            if positiveFrame.contains(touch.location(in: view)) {
                animate(view: btnPositive, withLabel: lblPositive, withColor: .black, toFrame: positiveFrame)
                lastTouchedButton = nil
                
                // submit answer and get response
                let response = viewModel.getResponse(answeredWith: .Positive, forFlashcardType: .Emotions)
                handle(response: response)
                
            } else if neutralFrame.contains(touch.location(in: view)) {
                animate(view: btnNeutral, withLabel: lblNeutral, withColor: .black, toFrame: neutralFrame)
                lastTouchedButton = nil
                
                // submit answer and get response
                let response = viewModel.getResponse(answeredWith: .Neutral, forFlashcardType: .Emotions)
                handle(response: response)
            } else if negativeFrame.contains(touch.location(in: view)) {
                animate(view: btnNegative, withLabel: lblNegative, withColor: .black, toFrame: negativeFrame)
                lastTouchedButton = nil
                
                // submit answer and get response
                let response = viewModel.getResponse(answeredWith: .Negative, forFlashcardType: .Emotions)
                handle(response: response)
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            if positiveFrame.contains(touch.location(in: view))  {
                if lastTouchedButton != btnPositive {
                    animate(view: btnPositive, withLabel: lblPositive, withColor: .gray, toFrame: CGRect(x: positiveFrame.minX + 4, y: positiveFrame.minY + 4, width: positiveFrame.width, height: positiveFrame.height))
                    
                    // if the last button was not nil, that means the user has slid off of another button
                    if lastTouchedButton != nil {
                        if lastTouchedButton == btnNeutral {
                            animate(view: btnNeutral, withLabel: lblNeutral, withColor: .black, toFrame: neutralFrame)
                        } else {
                            animate(view: btnNegative, withLabel: lblNegative, withColor: .black, toFrame: negativeFrame)
                        }
                        
                    }
                    
                    // no matter what, the last touched button now becomes...
                    lastTouchedButton = btnPositive
                }
            } else if neutralFrame.contains(touch.location(in: view)) {
                if lastTouchedButton != btnNeutral {
                    animate(view: btnNeutral, withLabel: lblNeutral, withColor: .gray, toFrame: CGRect(x: neutralFrame.minX + 4, y: neutralFrame.minY + 4, width: neutralFrame.width, height: neutralFrame.height))
                    
                    // animate any deslection needed
                    if lastTouchedButton != nil {
                        if lastTouchedButton == btnPositive {
                            animate(view: btnPositive, withLabel: lblPositive, withColor: .black, toFrame: positiveFrame)
                        } else {
                            animate(view: btnNegative, withLabel: lblNegative, withColor: .black, toFrame: negativeFrame)
                        }
                        
                    }
                    
                    lastTouchedButton = btnNeutral
                }
            } else if negativeFrame.contains(touch.location(in: view)) {
                if lastTouchedButton != btnNegative {
                    animate(view: btnNegative, withLabel: lblNegative, withColor: .gray, toFrame: CGRect(x: negativeFrame.minX + 4, y: negativeFrame.minY + 4, width: negativeFrame.width, height: negativeFrame.height))
                    
                    // animate any deslection needed
                    if lastTouchedButton != nil {
                        if lastTouchedButton == btnPositive {
                            animate(view: btnPositive, withLabel: lblPositive, withColor: .black, toFrame: positiveFrame)
                        } else {
                            animate(view: btnNeutral, withLabel: lblNeutral, withColor: .black, toFrame: neutralFrame)
                        }
                    }
                    
                    lastTouchedButton = btnNegative
                }
            } else if lastTouchedButton != nil {
                if lastTouchedButton == btnPositive {
                    animate(view: btnPositive, withLabel: lblPositive, withColor: .black, toFrame: positiveFrame)
                } else if lastTouchedButton == btnNeutral {
                    animate(view: btnNeutral, withLabel: lblNeutral, withColor: .black, toFrame: neutralFrame)
                } else {
                    animate(view: btnNegative, withLabel: lblNegative, withColor: .black, toFrame: negativeFrame)
                }
                
                lastTouchedButton = nil
            }
        } else if lastTouchedButton != nil {
            if lastTouchedButton == btnPositive {
                animate(view: btnPositive, withLabel: lblPositive, withColor: .black, toFrame: positiveFrame)
            } else if lastTouchedButton == btnNeutral {
                animate(view: btnNeutral, withLabel: lblNeutral, withColor: .black, toFrame: neutralFrame)
            } else {
                animate(view: btnNegative, withLabel: lblNegative, withColor: .black, toFrame: negativeFrame)
            }
            
            lastTouchedButton = nil
        }
    }
    
}
