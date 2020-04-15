//
//  CharmNewUserViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 4/23/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class CharmNewUserViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var txtConfirmPassword: UITextField!
    @IBOutlet weak var txtName: UITextField!
    
    // MARK: - Properties
    
    var existingEmail: String = ""
    var existingPassword: String = ""
    var isFromIntro: Bool = true
    
    // Activity View
    @IBOutlet weak var viewActivityContainer: UIView!
    @IBOutlet weak var viewActivity: UIActivityIndicatorView!
    
    // MARK: - View Lifecycle Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // set corner radius for activity view
        viewActivityContainer.layer.cornerRadius = 16
        
        // Load existing info
        if !existingEmail.isEmpty { txtEmail.text = existingEmail }
        if !existingPassword.isEmpty { txtPassword.text = existingPassword }
        
        // setup tap outside gesture
        let tapOut = UITapGestureRecognizer(target: self, action: #selector(tapOutside))
        view.addGestureRecognizer(tapOut)
        
        // setup textfield delegate
        txtEmail.delegate = self
        txtPassword.delegate = self
        txtName.delegate = self
        txtConfirmPassword.delegate = self
        
      //  setupToolbars()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIWindow.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIWindow.keyboardWillHideNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupToolbars() {
        let btnToEmail = UIButton(type: .custom)
        btnToEmail.setTitle("   Next   ", for: .normal)
        btnToEmail.layer.backgroundColor = UIColor(hex: "3B76BA").cgColor
        btnToEmail.addTarget(self, action: #selector(highlightEmail), for: .touchUpInside)
        let emailButton = UIBarButtonItem(customView: btnToEmail)
        
        let btnToPassword = UIButton(type: .custom)
        btnToPassword.setTitle("   Next   ", for: .normal)
        btnToPassword.layer.backgroundColor = UIColor(hex: "3B76BA").cgColor
        btnToPassword.addTarget(self, action: #selector(highlightPassword), for: .touchUpInside)
        let passwordButton = UIBarButtonItem(customView: btnToPassword)
        
        let btnToConfirmPassword = UIButton(type: .custom)
        btnToConfirmPassword.setTitle("   Next   ", for: .normal)
        btnToConfirmPassword.layer.backgroundColor = UIColor(hex: "3B76BA").cgColor
        btnToConfirmPassword.addTarget(self, action: #selector(highlightConfirmPassword), for: .touchUpInside)
        let confirmPasswordButton = UIBarButtonItem(customView: btnToConfirmPassword)
        
        let btnCreate = UIButton(type: .custom)
        btnCreate.setTitle("   Create Account   ", for: .normal)
        btnCreate.layer.backgroundColor = UIColor(hex: "3B76BA").cgColor
        btnCreate.addTarget(self, action: #selector(createAccountTapped(_:)), for: .touchUpInside)
        let createButton = UIBarButtonItem(customView: btnCreate)
        
        let nameToolbar = UIToolbar(frame:CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        nameToolbar.barStyle = .default
        nameToolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            emailButton
        ]
        
        let emailToolbar = UIToolbar(frame:CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        emailToolbar.barStyle = .default
        emailToolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            passwordButton
        ]
        
        let passwordToolbar = UIToolbar(frame:CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        passwordToolbar.barStyle = .default
        passwordToolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            confirmPasswordButton
        ]
        
        let confirmPasswordToolbar = UIToolbar(frame:CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        confirmPasswordToolbar.barStyle = .default
        confirmPasswordToolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            createButton
        ]
        
        nameToolbar.sizeToFit()
        emailToolbar.sizeToFit()
        passwordToolbar.sizeToFit()
        confirmPasswordToolbar.sizeToFit()
        
        btnToEmail.layer.cornerRadius = nameToolbar.frame.height * 0.4
        btnToPassword.layer.cornerRadius = emailToolbar.frame.height * 0.4
        btnCreate.layer.cornerRadius = passwordToolbar.frame.height * 0.4
        btnToConfirmPassword.layer.cornerRadius = passwordToolbar.frame.height * 0.4
        
        txtName.inputAccessoryView = nameToolbar
        txtEmail.inputAccessoryView = emailToolbar
        txtPassword.inputAccessoryView = passwordToolbar
        txtConfirmPassword.inputAccessoryView = confirmPasswordToolbar
    }
    
    @objc private func highlightEmail() {
        txtEmail.becomeFirstResponder()
    }
    
    @objc private func highlightPassword() {
        txtPassword.becomeFirstResponder()
    }
    
    @objc private func highlightConfirmPassword() {
        txtConfirmPassword.becomeFirstResponder()
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
    //    heightConstraint.constant = 8.0
        UIView.animate(withDuration: 0.25) {
      //      self.view.layoutIfNeeded()
        }
    }

    @objc private func keyboardWillHide(notification: NSNotification){
     //          heightConstraint.constant = heightConstraintDefault
         UIView.animate(withDuration: 0.25) {
       //      self.view.layoutIfNeeded()
         }
    }
    
    // MARK: - Activity Helpers
    
    private func startActivity() {
        view.isUserInteractionEnabled = false
        viewActivityContainer.alpha = 0.0
        viewActivityContainer.isHidden = false
        viewActivity.startAnimating()
        
        UIView.animate(withDuration: 0.25) {
            self.viewActivityContainer.alpha = 1.0
        }
    }
    
    private func stopActivity() {
        UIView.animate(withDuration: 0.25, animations: {
            self.viewActivityContainer.alpha = 0.0
        }) { (_) in
            self.viewActivity.stopAnimating()
            self.viewActivityContainer.isHidden = true
            self.view.isUserInteractionEnabled = true
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
        
        guard let confirmPassword = txtConfirmPassword.text, password == confirmPassword else {
            self.showAlert(withTitle: "Passwords are not same", andMessage: "Please enter same password in both fields.")
            return
        }
        
        guard let name = txtName.text, !name.isEmpty else {
            self.showAlert(withTitle: "Name Missing", andMessage: "Please enter your first name and try again.")
            return
        }

        createUser(withEmail: email, password: password, name: name)
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func swipeDismiss() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func tapOutside() {
        view.endEditing(true)
    }
    
    
    @IBAction func showSignUp(_ sender: UIButton) {
        if isFromIntro {
            self.performSegue(withIdentifier: "showSignIn", sender: self)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSignUp" {
            if let vc = segue.destination as? CharmSignInViewController {
                vc.isFromSignUp = true
            }
        }
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
        if textField == txtName {
            txtEmail.becomeFirstResponder()
        } else if textField == txtEmail {
            txtPassword.becomeFirstResponder()
        } else if textField == txtPassword {
            txtConfirmPassword.becomeFirstResponder()
        } else if textField == txtConfirmPassword {
            textField.resignFirstResponder()
            createAccountTapped(self)
        } else {
             textField.resignFirstResponder()
        }
        
        return true
    }
}

// MARK: - Account Creation

extension CharmNewUserViewController {
    
    func createUser(withEmail email: String, password: String, name: String) {
        startActivity()
        
        Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
            
            if let error = error, let errorCode = AuthErrorCode(rawValue: error._code) {
                self.stopActivity()
                switch errorCode {
                case .invalidEmail:
                    self.showAlert(withTitle: "Invalid Email", andMessage: "Please check the email address you entered and try again.")
                    return
                case .wrongPassword:
                    self.showAlert(withTitle: "Incorrect Password", andMessage: "Please check the password you entered and try again.")
                    return
                case .emailAlreadyInUse:
                    self.showAlert(withTitle: "Email in Use", andMessage: "The e-mail address you are trying to create an account with is already in use.")
                    return
                case .userNotFound:
                    self.showAlert(withTitle: "Not Found", andMessage: "An account was not found with the e-mail address provided.  Please check the e-mail address you entered and try again, or click on the create account button to create a new account using this e-mail address.")
                    return
                case .weakPassword:
                    self.showAlert(withTitle: "Weak Password", andMessage: "Your password must be at least 6 characters long.")
                    return
                default:
                    print("~>Unhandled error: \(error) with code: \(errorCode.rawValue)")
                    self.showAlert(withTitle: "Unknown Error", andMessage: "Unable to create an account at this time, please try again.")
                }
            }
            
            // no error so log the user in
            
            guard let user = Auth.auth().currentUser else {
                self.showAlert(withTitle: "Unknown Error", andMessage: "An unknown error occurred while logging in.  Please try again.")
                do {
                    try Auth.auth().signOut()
                } catch let error {
                    print("~>Got an error trying to sign out: \(error)")
                }
                self.stopActivity()
                return
            }
            
            let uid = user.uid
            let change = user.createProfileChangeRequest()
            change.displayName = name
            change.commitChanges(completion: { (error) in
                self.stopActivity()
                if let error = error {
                    print("~>There was an error creating the account: \(error)")
                } else {
                    self.loadUser(withUID: uid)
                }
            })
        }
    }
    
    private func loadUser(withUID uid: String) {
        // read user
        Database.database().reference().child(FirebaseStructure.usersLocation).child(uid).observeSingleEvent (of: .value) { (snapshot) in
            if snapshot.exists() {
                // setup a user item
                DispatchQueue.main.async {
                    do {
                        let user = try CharmUser(snapshot: snapshot)
                        FirebaseModel.shared.charmUser = user
                        self.showOnboarding()
                    } catch let error {
                        print("~>There was an error creating object: \(error)")
                        self.showLoginError()
                        return
                    }
                }
            } else {
                // create a new user
                print("~>Creating a new user")
                DispatchQueue.global(qos: .utility).async {
                    let info = self.getUserInfo()
                    print("~>User info: \(info)")
                    
                    let user = CharmUser(name: info.name, email: info.email, uid: uid)
                    
                    Database.database().reference().child(FirebaseStructure.usersLocation).child(uid).setValue(user.toAny())
                    FirebaseModel.shared.charmUser = user
                    DispatchQueue.main.async {
                        self.showOnboarding()
                    }
                }
            }
        }
    }
    
    // MARK: - Parse User's Name
    private func getUserInfo() -> (name: String, email: String) {
        guard let fullName = Auth.auth().currentUser?.displayName, let email = Auth.auth().currentUser?.email else {
            print("~>Unable to get name")
            return ("", "")
        }
        
        return (fullName, email)
    }
    
    private func showLoginError() {
        let loginError = UIAlertController(title: "Login Error", message: "Unable to login at this time.  Do you want to try again?", preferredStyle: .alert)
        loginError.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        loginError.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (_) in
            do {
                try Auth.auth().signOut()
            } catch let error {
                print("~>There was an error signing out: \(error)")
            }
            self.viewDidAppear(true)
        }))
        present(loginError, animated: true, completion: nil)
    }
    
    private func showOnboarding() {
        performSegue(withIdentifier: "showOnboarding", sender: nil)
    }
}
