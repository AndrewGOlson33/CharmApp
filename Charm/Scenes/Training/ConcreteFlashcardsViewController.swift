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

class ConcreteFlashcardsViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var scaleBar: ScaleBar!
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
        
        // setup scale bar
        scaleBar.setupBar(ofType: .Green, withValue: 0, andLabelPosition: 0)
        viewModel.getAverageScore { (concreteScores) in
            self.scaleBar.update(withValue: concreteScores.scoreValue, andCalculatedValue: concreteScores.averageScore)
            let tap = UITapGestureRecognizer(target: self, action: #selector(self.setupPopover))
            tap.numberOfTapsRequired = 1
            tap.numberOfTouchesRequired = 1
            self.scaleBar.addGestureRecognizer(tap)
        }
        
        
        // Start animating activity view and turn on firebase listener
        if viewModel.trainingModel.model.concreteNouns.count == 0 || viewModel.trainingModel.model.abstractNouns.count == 0 {
            viewLoading.layer.cornerRadius = 20
            viewLoading.isHidden = false
            activityIndicator.startAnimating()
            NotificationCenter.default.addObserver(self, selector: #selector(firebaseModelLoaded), name: FirebaseNotification.TrainingModelLoaded, object: nil)
        } else {
            firebaseModelLoaded()
        }
        
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
    
    // Setup Popover View
    @objc private func setupPopover() {
        let popoverContent = self.storyboard?.instantiateViewController(withIdentifier: StoryboardID.LabelPopover) as? LabelBubbleViewController
        popoverContent?.modalPresentationStyle = .popover
        popoverContent?.labelText = viewModel.shouldShowNA ? "N/A" : scaleBar.getStringValue(showPercentOnGreen: true)
        
        if let bubble = popoverContent?.popoverPresentationController {
            bubble.permittedArrowDirections = .down
            bubble.backgroundColor = #colorLiteral(red: 0.7843906283, green: 0.784409225, blue: 0.7843992114, alpha: 1)
            bubble.sourceView = scaleBar
            bubble.sourceRect = CGRect(x: getX(for: scaleBar), y: 0, width: 0, height: 0)
            bubble.delegate = self
            if let popoverController = popoverContent {
                present(popoverController, animated: true, completion: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                        popoverController.dismiss(animated: true, completion: nil)
                    })
                })
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
        lblWord.text = viewModel.getFlashCard()
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
        viewModel.getAverageScore { (newHistory) in
            DispatchQueue.main.async {
                self.scaleBar.update(withValue: newHistory.scoreValue, andCalculatedValue: newHistory.averageScore)
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
        viewModel.calculateAverageScore(addingCorrect: correct)
        
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
        let newWord = viewModel.getFlashCard()
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
        // overwrite old data with new data
        let blankHistory = ConcreteTrainingHistory()
        do {
            let data = try FirebaseEncoder().encode(blankHistory)
            Database.database().reference().child(FirebaseStructure.Users).child(Auth.auth().currentUser!.uid).child(FirebaseStructure.Training.TrainingDatabase).child(FirebaseStructure.Training.ConcreteHistory).setValue(data)
        } catch let errror {
            print("~>Got an error trying to encode a blank history: \(errror)")
            let alert = UIAlertController(title: "Unable to Reset", message: "Unable to reset scores at this time.  Please try again later.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
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
                let response = viewModel.getResponse(answeredConcrete: true)
                handle(response: response)
                
            } else if abstractFrame.contains(touch.location(in: view)) {
                animate(view: btnAbstract, withLabel: lblAbstract, withColor: .black, toFrame: abstractFrame)
                lastTouchedButton = nil
                
                // submit answer and get response
                let response = viewModel.getResponse(answeredConcrete: false)
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
            }
        } else if lastTouchedButton != nil {
            if lastTouchedButton == btnConcrete {
                animate(view: btnConcrete, withLabel: lblConcrete, withColor: .black, toFrame: concreteFrame)
            } else {
                animate(view: btnAbstract, withLabel: lblAbstract, withColor: .black, toFrame: abstractFrame)
            }
        }
    }
    
}

// MARK: - Popover Delegate

extension ConcreteFlashcardsViewController: UIPopoverPresentationControllerDelegate {
    //UIPopoverPresentationControllerDelegate inherits from UIAdaptivePresentationControllerDelegate, we will use this method to define the presentation style for popover presentation controller
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    //UIPopoverPresentationControllerDelegate
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        
    }
    
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        return true
    }
}
