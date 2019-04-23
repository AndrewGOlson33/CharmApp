//
//  CharmNewUserViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 4/23/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit

class CharmNewUserViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var viewOutter: UIView!
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var txtConfirmPassword: UITextField!
    @IBOutlet weak var txtFirst: UITextField!
    @IBOutlet weak var txtLast: UITextField!
    @IBOutlet weak var btnCreate: UIButton!
    
    // MARK: - Properties
    
    var existingEmail: String = ""
    var existingPassword: String = ""
    var delegate: NewUserDelegate? = nil
    
    // MARK: - View Lifecycle Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Round corners and setup shadows
        
        viewOutter.layer.cornerRadius = 20
        viewOutter.layer.shadowColor = UIColor.black.cgColor
        viewOutter.layer.shadowOpacity = 0.6
        viewOutter.layer.shadowRadius = 16.0
        viewOutter.layer.shadowOffset = CGSize(width: 2.0, height: 2.0)
        
        btnCreate.layer.cornerRadius = 8
        btnCreate.layer.shadowColor = UIColor.black.cgColor
        btnCreate.layer.shadowOpacity = 0.6
        btnCreate.layer.shadowRadius = 4.0
        btnCreate.layer.shadowOffset = CGSize(width: 2.0, height: 2.0)
        
        // Load existing info
        if !existingEmail.isEmpty { txtEmail.text = existingEmail }
        if !existingPassword.isEmpty { txtPassword.text = existingPassword }
        
        // setup dismiss gesture
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(swipeDismiss))
        swipe.direction = .down
        viewOutter.addGestureRecognizer(swipe)
    }

    // MARK: - Action Handling
    
    @IBAction func createAccountTapped(_ sender: Any) {
        view.endEditing(true)
        
        guard let email = txtEmail.text, !email.isEmpty else {
            self.showAlert(withTitle: "Email Missing", andMessage: "Please enter an email address and try again.")
            return
        }
        
        guard let password = txtPassword.text, !password.isEmpty else {
            self.showAlert(withTitle: "Password Missing", andMessage: "Please enter a password and try again.")
            return
        }
        
        guard let confirmPassword = txtConfirmPassword.text, !confirmPassword.isEmpty else {
            self.showAlert(withTitle: "Password Missing", andMessage: "Please enter the password confirmation and try again.")
            return
        }
        
        guard password == confirmPassword else {
            self.showAlert(withTitle: "Password Mismatch", andMessage: "Please make sure the passwords match and try.")
            return
        }
        
        guard let first = txtFirst.text, !first.isEmpty else {
            self.showAlert(withTitle: "Name Missing", andMessage: "Please enter your first name and try again.")
            return
        }
        
        guard let last = txtLast.text, !last.isEmpty else {
            self.showAlert(withTitle: "Name Missing", andMessage: "Please enter your last name and try again.")
            return
        }
        
        delegate?.createUser(withEmail: email, password: password, firstName: first, lastName: last)
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func swipeDismiss() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Private Helper Functions
    
    private func showAlert(withTitle title: String, andMessage message:String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
    
}
