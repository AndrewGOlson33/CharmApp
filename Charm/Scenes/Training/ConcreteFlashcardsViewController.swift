//
//  ConcreteFlashcardsViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 3/21/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase
import AVKit

class ConcreteFlashcardsViewController: UIViewController {
    
    // MARK: - IBOutlets

    @IBOutlet weak var lblCurrentStreak: UILabel!
    @IBOutlet weak var lblHighScore: UILabel!
    @IBOutlet weak var streakView: SliderView!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var viewFlashcards: UIView!
    @IBOutlet weak var lblWord: UILabel!
    @IBOutlet weak var viewLoading: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var lblResponsePhrase: UILabel!
    
    // button collection (they need borders and shadows)
    @IBOutlet var buttonCollection: [UIView]!
    @IBOutlet weak var btnConcrete: UIView!
    @IBOutlet weak var btnAbstract: UIView!
    
    // button contents
    @IBOutlet weak var lblConcrete: UILabel!
    @IBOutlet weak var lblAbstract: UILabel!
    
    
    // MARK: - Properties
    
    // View Model
    let viewModel = FlashcardsViewModel()
    
    // View Properties
    
    var concreteFrame: CGRect = CGRect.zero
    var abstractFrame: CGRect = CGRect.zero
    
    var lastTouchedButton: UIView? = nil
    
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
        }
        
        streakView.setup(for: .fillFromLeft)
        
        viewModel.getAverageConcreteScore { (concreteScores) in
            self.lblCurrentStreak.text = concreteScores.currentStreakDetail
            self.lblHighScore.text = concreteScores.highScoreDetail
            self.streakView.updatePosition(to: CGFloat(concreteScores.percentOfRecord))
        }
        
        
        // Start animating activity view and turn on firebase listener
        if viewModel.trainingModel.model.concreteNounFlashcards.count == 0 || viewModel.trainingModel.model.abstractNounConcreteFlashcards.count == 0 {
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
        tabBarController?.navigationItem.title = "Concrete"
        let info = UIBarButtonItem(image: UIImage(named: Image.Info), style: .plain, target: self, action: #selector(infoButtonTapped))
        tabBarController?.navigationItem.rightBarButtonItem = info
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // set the original frames to use for animations
        concreteFrame = btnConcrete.frame
        abstractFrame = btnAbstract.frame
        
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
        
        guard let info = storyboard?.instantiateViewController(withIdentifier: StoryboardID.Info) as? InfoDetailViewController else { return }
        info.type = .Ideas
        tabBarController?.navigationController?.pushViewController(info, animated: true)
    }
    
    // Get calculated x coord for scalebar
    private func getX(for bar: ScaleBar) -> CGFloat {
        let value = CGFloat(bar.calculatedValue)
        print("~>Value: \(value) point: \(bar.bounds.width * value + bar.frame.origin.x) midX: \(bar.frame.midX)")
        return bar.bounds.width * value
    }
    
    // Setup UI once the firebase model is loaded
    @objc private func firebaseModelLoaded() {
        // remove listener
        NotificationCenter.default.removeObserver(self, name: FirebaseNotification.TrainingModelLoaded, object: nil)
        
        // setup first flashcard
        lblWord.text = viewModel.getFlashCard().capitalizedFirst
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
    
    @objc private func trainingHistoryUpdated() {
        viewModel.getAverageConcreteScore { (newHistory) in
            DispatchQueue.main.async {
                self.lblCurrentStreak.text = newHistory.currentStreakDetail
                self.lblHighScore.text = newHistory.highScoreDetail
                self.streakView.updatePosition(to: CGFloat(newHistory.percentOfRecord))
            }
        }
    }
    
    // Handle Updates After Answer is Submitted
    
    private func handle(response: (response: String, correct: Bool)) {
        animate(responseText: response.response)
        updateScore(withCorrectAnswer: response.correct)
    }
    
    // Updates Score
    private func updateScore(withCorrectAnswer correct: Bool) {
        viewModel.calculateAverageScore(addingCorrect: correct)
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
        let newWord = viewModel.getFlashCard().capitalizedFirst
        UIView.animate(withDuration: 0.25, delay: 0.05, animations: {
            self.lblWord.alpha = 0.0
        }) { (_) in
            self.lblWord.text = newWord
            UIView.animate(withDuration: 0.25, animations: {
                self.lblWord.alpha = 1.0
            }, completion: { (_) in
                self.lblResponsePhrase.isHidden = true
                self.updateFlashcard()
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
        viewModel.resetRecord(forType: .Concrete)
    }
    
}

extension ConcreteFlashcardsViewController: UIGestureRecognizerDelegate {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            
            if concreteFrame.contains(touch.location(in: view)) {
                animate(view: btnConcrete, withLabel: lblConcrete, withColor: .gray, toFrame: CGRect(x: concreteFrame.minX + 4, y: concreteFrame.minY + 4, width: concreteFrame.width, height: concreteFrame.height))
                lastTouchedButton = btnConcrete
            } else if abstractFrame.contains(touch.location(in: view)) {
                animate(view: btnAbstract, withLabel: lblAbstract, withColor: .gray, toFrame: CGRect(x: abstractFrame.minX + 4, y: abstractFrame.minY + 4, width: abstractFrame.width, height: abstractFrame.height))
                lastTouchedButton = btnAbstract
            }
            
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard lastTouchedButton != nil else { return }
        if let touch = touches.first {
            if concreteFrame.contains(touch.location(in: view)) {
                animate(view: btnConcrete, withLabel: lblConcrete, withColor: .black, toFrame: concreteFrame)
                lastTouchedButton = nil
                
                // submit answer and get response
                let response = viewModel.getResponse(answeredWith: .Concrete, forFlashcardType: .Concrete)
                handle(response: response)
                
            } else if abstractFrame.contains(touch.location(in: view)) {
                animate(view: btnAbstract, withLabel: lblAbstract, withColor: .black, toFrame: abstractFrame)
                lastTouchedButton = nil
                
                // submit answer and get response
                let response = viewModel.getResponse(answeredWith: .Abstract, forFlashcardType: .Concrete)
                handle(response: response)
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            if concreteFrame.contains(touch.location(in: view))  {
                if lastTouchedButton != btnConcrete {
                    animate(view: btnConcrete, withLabel: lblConcrete, withColor: .gray, toFrame: CGRect(x: concreteFrame.minX + 4, y: concreteFrame.minY + 4, width: concreteFrame.width, height: concreteFrame.height))
                    
                    // if the last button was not nil, that means the user has slid off of another button
                    if lastTouchedButton != nil {
                        animate(view: btnAbstract, withLabel: lblAbstract, withColor: .black, toFrame: abstractFrame)
                    }
                    
                    // no matter what, the last touched button now becomes...
                    lastTouchedButton = btnConcrete
                }
            } else if abstractFrame.contains(touch.location(in: view)) {
                if lastTouchedButton != btnAbstract {
                    animate(view: btnAbstract, withLabel: lblAbstract, withColor: .gray, toFrame: CGRect(x: abstractFrame.minX + 4, y: abstractFrame.minY + 4, width: abstractFrame.width, height: abstractFrame.height))
                    
                    // animate any deslection needed
                    if lastTouchedButton != nil {
                        animate(view: btnConcrete, withLabel: lblConcrete, withColor: .black, toFrame: concreteFrame)
                    }
                    
                    lastTouchedButton = btnAbstract
                }
            } else if lastTouchedButton != nil {
                if lastTouchedButton == btnConcrete {
                    animate(view: btnConcrete, withLabel: lblConcrete, withColor: .black, toFrame: concreteFrame)
                } else {
                    animate(view: btnAbstract, withLabel: lblAbstract, withColor: .black, toFrame: abstractFrame)
                }
                
                lastTouchedButton = nil
            }
        } else if lastTouchedButton != nil {
            if lastTouchedButton == btnConcrete {
                animate(view: btnConcrete, withLabel: lblConcrete, withColor: .black, toFrame: concreteFrame)
            } else {
                animate(view: btnAbstract, withLabel: lblAbstract, withColor: .black, toFrame: abstractFrame)
            }
            
            lastTouchedButton = nil
        }
    }
    
}
