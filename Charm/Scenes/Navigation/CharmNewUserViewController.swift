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
    
    // for keyboard
    
    var originY: CGFloat = -1.0
    var keyboardSize: CGRect? = nil
    
    // MARK: - View Lifecycle Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Round corners and setup shadows
        
        btnCreate.layer.cornerRadius = 8
        btnCreate.layer.shadowColor = UIColor.black.cgColor
        btnCreate.layer.shadowOpacity = 0.6
        btnCreate.layer.shadowRadius = 4.0
        btnCreate.layer.shadowOffset = CGSize(width: 2.0, height: 2.0)
        
        // Load existing info
        if !existingEmail.isEmpty { txtEmail.text = existingEmail }
        if !existingPassword.isEmpty { txtPassword.text = existingPassword }
        
        // setup tap outside gesture
        let tapOut = UITapGestureRecognizer(target: self, action: #selector(tapOutside))
        view.addGestureRecognizer(tapOut)
        
        // setup textfield delegate
        txtEmail.delegate = self
        txtPassword.delegate = self
        txtConfirmPassword.delegate = self
        txtFirst.delegate = self
        txtLast.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if originY == -1.0 { originY = view.frame.origin.y }
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardwillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Keyboard frame setting
    
    @objc private func keyboardwillShow(_ sender: Notification) {
        if let size = (sender.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            print("notification: Got size: \(size)")
            keyboardSize = size
        }
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
    
    @objc private func tapOutside() {
        view.endEditing(true)
    }
    
    // MARK: - Private Helper Functions
    
    private func showAlert(withTitle title: String, andMessage message:String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
    
}

extension CharmNewUserViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == txtEmail {
            txtPassword.becomeFirstResponder()
        } else if textField == txtPassword {
            txtConfirmPassword.becomeFirstResponder()
        } else if textField == txtConfirmPassword {
            txtFirst.becomeFirstResponder()
        } else if textField == txtFirst {
            txtLast.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.0) {
            guard let keyboardFrame = self.keyboardSize else {
                print("~>No keyboard frame size.")
                return
            }
            
            let fieldFrame = textField.frame
            let navigationBarHeight: CGFloat = self.navigationController!.navigationBar.frame.height
            let difference = keyboardFrame.minY - fieldFrame.maxY - navigationBarHeight - 32
            print("~>There is a difference of: \(difference)")
            
            if difference < 0 {
                self.view.frame.origin.y += difference
            }
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        view.frame.origin.y = originY
    }
    
}
