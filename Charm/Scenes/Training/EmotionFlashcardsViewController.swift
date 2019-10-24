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

class EmotionFlashcardsViewController: UIViewController, FlashcardsHistoryDelegate {

    // MARK: - IBOutlets
    
    @IBOutlet weak var lblStreak: UILabel!
    @IBOutlet weak var streakBar: SliderView!
    @IBOutlet weak var lblHighScore: UILabel!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var lblWord: UILabel!
    @IBOutlet weak var viewLoading: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var lblResponsePhrase: UILabel!
    
    // button collection (they need borders and shadows)
    @IBOutlet var buttonCollection: [UIView]!
    @IBOutlet weak var btnPositive: UIView!
    @IBOutlet weak var btnNegative: UIView!
    
    // button contents
    @IBOutlet weak var lblPositive: UILabel!
    @IBOutlet weak var lblNegative: UILabel!
    
    
    // MARK: - Properties
    
    // View Model
    let viewModel = FlashcardsViewModel()
    
    // View Properties
    
    var positiveFrame: CGRect = CGRect.zero
    var negativeFrame: CGRect = CGRect.zero
    
    var lastTouchedButton: UIView? = nil
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup borders and shadows for buttons
        for button in buttonCollection {
            button.layer.cornerRadius = 4
        }
        
        streakBar.alpha = 0.0
        viewModel.delegate = self
        
        // Start animating activity view and turn on firebase listener
        if viewModel.trainingModel.model.positiveWords.count == 0 || viewModel.trainingModel.model.negativeWords.count == 0 || viewModel.trainingModel.model.abstractNounConcreteFlashcards.count == 0 {
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
        let info = UIBarButtonItem(title: "Learn More", style: .plain, target: self, action: #selector(infoButtonTapped))
        tabBarController?.navigationItem.rightBarButtonItem = info
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // setup streak bar
        
        streakBar.setup(for: .fillFromLeft)
        
        viewModel.getAverageEmotionsScore { (emotionsScores) in
            // make sure this is done on main thread
            DispatchQueue.main.async {
                self.lblStreak.text = emotionsScores.currentStreakDetail
                self.lblHighScore.text = emotionsScores.highScoreDetail
                self.streakBar.updatePosition(to: CGFloat(emotionsScores.percentOfRecord))
                
                UIView.animate(withDuration: 0.5, animations: {
                    self.streakBar.alpha = 1.0
                })
            }
            
        }
        
        
        // set the original frames to use for animations
        positiveFrame = btnPositive.frame
        negativeFrame = btnNegative.frame
        
        // setup listener for when score updates
        NotificationCenter.default.addObserver(self, selector: #selector(historyUpdatedFromServer), name: FirebaseNotification.TrainingHistoryUpdated, object: nil)
    }
    
    // Remove observer when view is not visible
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: FirebaseNotification.TrainingHistoryUpdated, object: nil)
        
        // Save history when leaving screen
        guard let uid = CharmUser.shared.id else { return }
        var history: TrainingHistory!
        
        if let existing = CharmUser.shared.trainingData {
            history = existing
        } else {
            history = TrainingHistory()
        }
        
        DispatchQueue.global(qos: .utility).async {
            do {
                let data = try FirebaseEncoder().encode(history)
                print("~>Setting data on: \(uid) with: \(data)")
               let reference = Database.database().reference().child(FirebaseStructure.Users).child(uid).child(FirebaseStructure.Training.TrainingDatabase)
                reference.keepSynced(true)
                reference.setValue(data) { (error, reference) in
                    print("~>Error: \(String(describing: error)) reference: \(reference)")
                    print("~>Completed set value.")
                }
            } catch let error {
                print("~>There was an error converting the data: \(error)")
            }
        }
    }
    
    // MARK: - Private Helper Functions
    
    @objc private func infoButtonTapped() {
        guard let info = storyboard?.instantiateViewController(withIdentifier: StoryboardID.Info) as? InfoDetailViewController else { return }
        info.type = .Emotions
        tabBarController?.navigationController?.pushViewController(info, animated: true)
    }
    
    // Setup UI once the firebase model is loaded
    @objc private func firebaseModelLoaded() {
        // remove listener
        NotificationCenter.default.removeObserver(self, name: FirebaseNotification.TrainingModelLoaded, object: nil)
        
        // setup first flashcard
        lblWord.text = viewModel.getFlashCard(ofType: .Emotions).capitalizedFirst
        lblWord.alpha = 0.0
        lblWord.isHidden = false
        
        UIView.animate(withDuration: 0.25, animations: {
            self.lblWord.alpha = 1.0
            self.viewLoading.alpha = 0.0
        }) { (_) in
            self.activityIndicator.stopAnimating()
            self.viewLoading.isHidden = true
        }
        
    }
    
    // Updates UI When Training Data Updates
    
    @objc private func historyUpdatedFromServer() {
        NotificationCenter.default.removeObserver(self, name: FirebaseNotification.TrainingHistoryUpdated, object: nil)
        trainingHistoryUpdated()
    }
    
    func trainingHistoryUpdated() {
        
        viewModel.getAverageEmotionsScore { (newHistory) in
            DispatchQueue.main.async {
                self.lblStreak.text = newHistory.currentStreakDetail
                self.lblHighScore.text = newHistory.highScoreDetail
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
        
        // prevent taps while animation is going on
        view.isUserInteractionEnabled = false
        
        UIView.animate(withDuration: 0.2, animations: {
            self.lblResponsePhrase.alpha = 1.0
        }) { (_) in
            UIView.animate(withDuration: 0.25, delay: 0.05, animations: {
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
        UIView.animate(withDuration: 0.25, delay: 0.05, animations: {
            self.lblWord.alpha = 0.0
        }) { (_) in
            self.lblWord.text = newWord
            UIView.animate(withDuration: 0.25, animations: {
                self.lblWord.alpha = 1.0
            }, completion: { (_) in
                // resume taps since animation is done
                self.view.isUserInteractionEnabled = true
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
                animate(view: btnPositive, withLabel: lblPositive, withColor: .white, toFrame: positiveFrame)
                lastTouchedButton = nil
                
                // submit answer and get response
                let response = viewModel.getResponse(answeredWith: .Positive, forFlashcardType: .Emotions)
                handle(response: response)
                
            } else if negativeFrame.contains(touch.location(in: view)) {
                animate(view: btnNegative, withLabel: lblNegative, withColor: .white, toFrame: negativeFrame)
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
                        animate(view: btnNegative, withLabel: lblNegative, withColor: .white, toFrame: negativeFrame)
                    }
                    
                    // no matter what, the last touched button now becomes...
                    lastTouchedButton = btnPositive
                }
            } else if negativeFrame.contains(touch.location(in: view)) {
                if lastTouchedButton != btnNegative {
                    animate(view: btnNegative, withLabel: lblNegative, withColor: .gray, toFrame: CGRect(x: negativeFrame.minX + 4, y: negativeFrame.minY + 4, width: negativeFrame.width, height: negativeFrame.height))
                    
                    // animate any deslection needed
                    if lastTouchedButton != nil {
                        if lastTouchedButton == btnPositive {
                            animate(view: btnPositive, withLabel: lblPositive, withColor: .white, toFrame: positiveFrame)
                        }
                    }
                    
                    lastTouchedButton = btnNegative
                }
            } else if lastTouchedButton != nil {
                if lastTouchedButton == btnPositive {
                    animate(view: btnPositive, withLabel: lblPositive, withColor: .white, toFrame: positiveFrame)
                } else {
                    animate(view: btnNegative, withLabel: lblNegative, withColor: .white, toFrame: negativeFrame)
                }
                
                lastTouchedButton = nil
            }
        } else if lastTouchedButton != nil {
            if lastTouchedButton == btnPositive {
                animate(view: btnPositive, withLabel: lblPositive, withColor: .white, toFrame: positiveFrame)
            } else {
                animate(view: btnNegative, withLabel: lblNegative, withColor: .white, toFrame: negativeFrame)
            }
            
            lastTouchedButton = nil
        }
    }
    
}
