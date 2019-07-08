//
//  CharmSignInViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 3/6/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import CodableFirebase
import Contacts
import AVKit

class CharmSignInViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var viewActivity: UIActivityIndicatorView!
    @IBOutlet weak var viewActivityContainer: UIView!
    
    // MARK: - Properties
    
    // MARK: - Lifecyle Functions

    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewActivityContainer.layer.cornerRadius = 16
        
        // set delegate methods
        txtEmail.delegate = self
        txtPassword.delegate = self
        
        // setup tap outside gesture
        let tapOut = UITapGestureRecognizer(target: self, action: #selector(tapOutside))
        view.addGestureRecognizer(tapOut)
        
        setupToolbars()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        txtEmail.becomeFirstResponder()
    }
    
    private func setupToolbars() {
        let btnForgotPassword = UIBarButtonItem(title: "Forgot password?", style: .plain, target: self, action: #selector(forgotPasswordButtonTapped(_:)))
        let btnNext = UIButton(type: .custom)
        btnNext.setTitle("   Next   ", for: .normal)
        btnNext.layer.backgroundColor = #colorLiteral(red: 0.1140055135, green: 0.630348742, blue: 0.9489882588, alpha: 1)
        btnNext.addTarget(self, action: #selector(highlightPassword), for: .touchUpInside)
        let nextButton = UIBarButtonItem(customView: btnNext)
        let btnLogin = UIButton(type: .custom)
        btnLogin.setTitle("   Login   ", for: .normal)
        btnLogin.layer.backgroundColor = #colorLiteral(red: 0.1140055135, green: 0.630348742, blue: 0.9489882588, alpha: 1)
        btnLogin.addTarget(self, action: #selector(loginButtonTapped(_:)), for: .touchUpInside)
        let loginButton = UIBarButtonItem(customView: btnLogin)
        
        let emailToolbar = UIToolbar(frame:CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        emailToolbar.barStyle = .default
        emailToolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            nextButton
        ]
        
        let passwordToolbar = UIToolbar(frame:CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        passwordToolbar.barStyle = .default
        passwordToolbar.items = [
            btnForgotPassword,
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            loginButton
        ]
        
        emailToolbar.sizeToFit()
        passwordToolbar.sizeToFit()
        
        btnNext.layer.cornerRadius = emailToolbar.frame.height * 0.4
        btnLogin.layer.cornerRadius = passwordToolbar.frame.height * 0.4
        
        txtEmail.inputAccessoryView = emailToolbar
        txtPassword.inputAccessoryView = passwordToolbar
        
    }
    
    
    @objc private func tapOutside() {
        view.endEditing(true)
    }
    
    @objc private func highlightPassword() {
        txtPassword.becomeFirstResponder()
    }
    
    private func showNavigation() {
        DispatchQueue.main.async {
            let nav = self.storyboard?.instantiateViewController(withIdentifier: StoryboardID.NavigationHome)
            let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
            // clear out any calls as needed
            appDelegate.window?.rootViewController = nav
            appDelegate.window?.makeKeyAndVisible()
        }
    }
    
    private func showLoginError() {
        let loginError = UIAlertController(title: "Login Error", message: "Unable to login at this time.  Do you want to try again?", preferredStyle: .alert)
        loginError.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        loginError.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (_) in
            self.viewDidAppear(true)
        }))
        present(loginError, animated: true, completion: nil)
    }
    
    // MARK: - Private Helper Functions
    
    private func showAlert(withTitle title: String, andMessage message:String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
    
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
    
    // MARK: - Button Handling
    
    @IBAction func loginButtonTapped(_ sender: Any) {
        
        view.endEditing(true)
        startActivity()
        
        guard let email = txtEmail.text, !email.isEmpty else {
            showAlert(withTitle: "Check Email", andMessage: "Please make sure you have entered your e-mail address and try again.")
            self.stopActivity()
            return
        }
        
        guard let password = txtPassword.text, !password.isEmpty else {
            showAlert(withTitle: "Check Password", andMessage: "Please make sure you have entered your password and try again.")
            self.stopActivity()
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
            
            self.stopActivity()
            
            if let error = error, let errorCode = AuthErrorCode(rawValue: error._code) {
                switch errorCode {
                case .invalidEmail:
                    self.showAlert(withTitle: "Invalid Email", andMessage: "Please check the email address you entered and try again.")
                    return
                case .wrongPassword:
                    self.showAlert(withTitle: "Incorrect Password", andMessage: "Please check the password you entered and try again.")
                    return
                case .userNotFound:
                    self.showAlert(withTitle: "Not Found", andMessage: "An account was not found with the e-mail address provided.  Please check the e-mail address you entered and try again, or click on the create account button to create a new account using this e-mail address.")
                    return
                default:
                    print("~>Unhandled error: \(error) with code: \(errorCode.rawValue)")
                    self.showAlert(withTitle: "Case Not Handled", andMessage: "ErrorCode: \(errorCode)")
                }
            }
            
            // no error so log the user in
            
            guard let uid = Auth.auth().currentUser?.uid else {
                self.showAlert(withTitle: "Unknown Error", andMessage: "An unknown error occurred while logging in.  Please try again.")
                do {
                    try Auth.auth().signOut()
                } catch let error {
                    print("~>Got an error trying to sign out: \(error)")
                }
                
                return
            }
            
            self.loadUser(withUID: uid)
        }
        
    }
    
    @IBAction func forgotPasswordButtonTapped(_ sender: Any) {
        guard let email = txtEmail.text, !email.isEmpty else {
            showAlert(withTitle: "Check Email", andMessage: "Please make sure you have entered your e-mail address and try again.")
            return
        }
        
        startActivity()
        
        let resetPasswordAlert = UIAlertController(title: "Confirm Reset", message: "Are you sure you want to reset your password?", preferredStyle: .alert)
        resetPasswordAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        resetPasswordAlert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { (_) in
            self.stopActivity()
            Auth.auth().sendPasswordReset(withEmail: email, completion: { (error) in
                if let error = error, let errorCode = AuthErrorCode(rawValue: error._code) {
                    switch errorCode {
                    case .userNotFound:
                        self.showAlert(withTitle: "Not Found", andMessage: "A user with this e-mail address was not found.")
                        return
                    case .invalidEmail:
                        self.showAlert(withTitle: "Invalid Email", andMessage: "The email address you entered was not valid.")
                        return
                    default:
                        print("~>Unhandled error: \(error) with code: \(errorCode.rawValue)")
                        self.showAlert(withTitle: "Failed", andMessage: "Your password was not able to be reset at this time.")
                        return
                    }
                } else if let error = error {
                    print("~>Unhandled error: \(error)")
                    self.showAlert(withTitle: "Failed", andMessage: "Your password was not able to be reset at this time.")
                    return
                } else {
                    self.showAlert(withTitle: "Success", andMessage: "Please check your inbox for a link to reset your password.")
                    return
                }
            })
        }))
        
        present(resetPasswordAlert, animated: true, completion: nil)
    }
    
    @IBAction func createNewAccountTapped(_ sender: Any) {
        view.endEditing(true)
        performSegue(withIdentifier: SegueID.NewUser, sender: self)
    }
    
    @IBAction func productDemoButtonTapped(_ sender: Any) {
        let avPlayerVC = AVPlayerViewController()
        avPlayerVC.entersFullScreenWhenPlaybackBegins = true
        let videoStorage = Storage.storage()
        
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
    
    // MARK: - Sign in Functions
    
    private func loadUser(withUID uid: String) {
        // read user
        Database.database().reference().child(FirebaseStructure.Users).child(uid).observeSingleEvent (of: .value) { (snapshot) in
            if snapshot.exists() {
                // setup a user item
                guard let value = snapshot.value else { fatalError("~>Unable to get value from snapshot") }
                DispatchQueue.main.async {
                    do {
                        let user = try FirebaseDecoder().decode(CharmUser.self, from: value)
                        CharmUser.shared = user
                        self.showNavigation()
                    } catch let error {
                        print("~>There was an error creating object: \(error)")
                        self.showLoginError()
                        return
                    }
                }
                
            } else {
                // create a new user
                print("~>Creating a new user")
                DispatchQueue.main.async {
                    let info = self.getUserInfo()
                    print("~>User info: \(info)")
                    var user = CharmUser(name: info.name, email: info.email)
                    user.id = uid
                    
                    do {
                        let data = try FirebaseEncoder().encode(user)
                        Database.database().reference().child(FirebaseStructure.Users).child(uid).setValue(data)
                        CharmUser.shared = user
                        self.showNavigation()
                    } catch let error {
                        print("~>There was an error encoding user: \(error)")
                        self.showLoginError()
                        return
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

}

// MARK: - TextField Delegate

extension CharmSignInViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == txtEmail {
            txtPassword.becomeFirstResponder()
        } else if textField == txtPassword {
            textField.resignFirstResponder()
            loginButtonTapped(self)
        } else {
            textField.resignFirstResponder()
        }
        
        return true
    }
    
}
