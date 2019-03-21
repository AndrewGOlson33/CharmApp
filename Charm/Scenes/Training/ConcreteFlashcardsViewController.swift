//
//  ConcreteFlashcardsViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 3/21/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit

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
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // set the original frames to use for animations
        concreteFrame = btnConcrete.frame
        abstractFrame = btnAbstract.frame
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
            } else if abstractFrame.contains(touch.location(in: view)) {
                animate(view: btnAbstract, withLabel: lblAbstract, withColor: .black, toFrame: abstractFrame)
                lastTouchedButton = nil
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
    
    private func animate(view: UIView, withLabel label: UILabel, withColor color: UIColor, toFrame frame: CGRect) {
        UIView.animate(withDuration: 0.2, animations: {
            view.frame = frame
            label.textColor = color
        })
    }
    
}
