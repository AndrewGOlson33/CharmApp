//
//  InfoModuleViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 4/12/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit

class InfoModuleViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var outsideView: UIView!
    @IBOutlet weak var txtPolicy: UITextView!
    @IBOutlet weak var txtTermsofUse: UITextView!
    
    // MARK: - Properties
    
    var documentType: DocumentType!
    
    // MARK: - View Lifecycle Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard documentType != nil else {
            dismiss(animated: true, completion: nil)
            return
        }
        
        switch documentType! {
        case .PrivacyPolicy:
            txtPolicy.isHidden = false
            txtTermsofUse.isHidden = true
        case .TermsOfUse:
            txtTermsofUse.isHidden = false
            txtPolicy.isHidden = true
        }
        
        // Configure View
        outsideView.layer.cornerRadius = 20
        outsideView.layer.borderColor = UIColor.black.cgColor
        outsideView.layer.borderWidth = 2.0
        outsideView.layer.shadowColor = UIColor.black.cgColor
        outsideView.layer.shadowOpacity = 0.6
        outsideView.layer.shadowRadius = 8
        outsideView.layer.shadowOffset = CGSize(width: 2.0, height: 2.0)
        
        // Add Dismiss Gesture
        let tapOutside = UITapGestureRecognizer(target: self, action: #selector(closeButtonTapped(_:)))
        tapOutside.numberOfTapsRequired = 1
        tapOutside.numberOfTouchesRequired = 1
        tapOutside.delegate = self
        self.view.addGestureRecognizer(tapOutside)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(closeButtonTapped(_:)))
        swipeDown.direction = .down
        swipeDown.numberOfTouchesRequired = 1
        outsideView.addGestureRecognizer(swipeDown)
    }
    
    // MARK: - Button Handling

    @IBAction func closeButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

extension InfoModuleViewController: UIGestureRecognizerDelegate {
    
    // only allow touch outside of view
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let hit = self.view.hitTest(touch.location(in: view), with: nil)
        return hit == self.view
    }
}
