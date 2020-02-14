//
//  SendFeedbackViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 4/12/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit

class SendFeedbackViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var outsideView: UIView!
    @IBOutlet weak var txtFeedbackEntry: UITextView!
    
    // MARK: - Properties
    
    var appDelegate: AppDelegate!
    var existingReports = BugReports.shared
    var titleString: String? = nil

    // MARK: - View Lifecycle Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let text = titleString {
            lblTitle.text = text
        }

        // setup view
        outsideView.layer.cornerRadius = 20
        outsideView.layer.borderColor = UIColor.black.cgColor
        outsideView.layer.borderWidth = 2.0
        outsideView.layer.shadowColor = UIColor.black.cgColor
        outsideView.layer.shadowOpacity = 0.6
        outsideView.layer.shadowRadius = 8
        outsideView.layer.shadowOffset = CGSize(width: 2.0, height: 2.0)
        outsideView.clipsToBounds = false
        
        // Add Dismiss Keyboard Gesture
        let tapOutside = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tapOutside.numberOfTapsRequired = 1
        tapOutside.numberOfTouchesRequired = 1
        self.view.addGestureRecognizer(tapOutside)
        
        // Add Swipe down gesture
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(btnCancelTapped(_:)))
        swipeDown.direction = .down
        swipeDown.numberOfTouchesRequired = 1
        outsideView.addGestureRecognizer(swipeDown)
        
        // setup textview
        txtFeedbackEntry.layer.borderColor = UIColor.black.cgColor
        txtFeedbackEntry.layer.borderWidth = 1
        txtFeedbackEntry.layer.cornerRadius = 8
        txtFeedbackEntry.delegate = self
        
        // Setup App Delegate
        DispatchQueue.main.async {
            self.appDelegate = UIApplication.shared.delegate as? AppDelegate
        }
    }
    
    // MARK: - Gesture Handling
    
    @objc private func hideKeyboard() {
        if txtFeedbackEntry.isFirstResponder { txtFeedbackEntry.resignFirstResponder() }
    }
    
    // MARK: - Button Handling

    @IBAction func btnCancelTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnSendTapped(_ sender: Any) {
        txtFeedbackEntry.resignFirstResponder()
        guard let text = txtFeedbackEntry.text else {
            let noTextAlert = UIAlertController(title: "Please Enter Feedback", message: "Please enter some feedback before sending it.", preferredStyle: .alert)
            noTextAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(noTextAlert, animated: true, completion: nil)
            return
        }
        
        guard let _ = FirebaseModel.shared.charmUser else {
            let noTextAlert = UIAlertController(title: "Connection Error", message: "There was an error submitting your feedback, please try again in a moment.", preferredStyle: .alert)
            noTextAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(noTextAlert, animated: true, completion: nil)
            return
        }
        
        let email = FirebaseModel.shared.charmUser.userProfile.email
        print("~>Adding feedback: \(text)")
        existingReports.addReport(withText: text, fromUser: email)
        dismiss(animated: true, completion: nil)
    }
}

extension SendFeedbackViewController: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        UIView.animate(withDuration: 0.25) {
            self.view.frame.origin.y -= self.view.frame.height * 0.25
        }
        
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        UIView.animate(withDuration: 0.25) {
            self.view.frame.origin.y = 0
        }
        
    }
}
