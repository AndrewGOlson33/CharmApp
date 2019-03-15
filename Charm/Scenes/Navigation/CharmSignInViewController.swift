//
//  CharmSignInViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 3/6/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit
import Firebase
import FirebaseUI
import CodableFirebase

class CharmSignInViewController: UIViewController {
    
    // MARK: - Properties
    
    var authUI: FUIAuth!
    
    // MARK: - Lifecyle Functions

    override func viewDidLoad() {
        super.viewDidLoad()

        authUI = FUIAuth.defaultAuthUI()
        authUI.providers = [FUIEmailAuth()]
        
        authUI.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // check if user exists
        guard let user = Auth.auth().currentUser else {
            showLoginScreen()
            return
        }
        
        user.getIDTokenResult(forcingRefresh: true) { (result, error) in
            if let _ = error {
                print("~>Need to show login screen.")
                self.showLoginScreen()
            } else {
                guard let uid = Auth.auth().currentUser?.uid else {
                    print("~>There was an error getting the user's UID.")
                    self.showLoginError()
                    return
                }
                self.loadUser(withUID: uid)
            }
        }
        
    }
    
    private func showLoginScreen() {
        let authViewController = authUI!.authViewController()
        present(authViewController, animated: true, completion: nil)
    }
    
    private func showNavigation() {
        DispatchQueue.main.async {
            let nav = self.storyboard?.instantiateViewController(withIdentifier: StoryboardID.NavigationHome)
            let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
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

}

// MARK: - Sign in Delegate

extension CharmSignInViewController: FUIAuthDelegate {
    
    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
        print("~>Got a result: \(authDataResult.debugDescription)")
        
        guard let result = authDataResult else {
            print("~>Unable to get an auth result.")
            showLoginError()
            return
        }
        let uid = result.user.uid
        loadUser(withUID: uid)
    }
    
    // MARK: - Load User
    
    private func loadUser(withUID uid: String) {
        // read user
        Database.database().reference().child(FirebaseStructure.Users).child(uid).observeSingleEvent (of: .value) { (snapshot) in
            if snapshot.exists() {
                // setup a user item
                guard let value = snapshot.value else { fatalError("~>Unable to get value from snapshot") }
                DispatchQueue.main.async {
                    do {
                        let user = try FirebaseDecoder().decode(CharmUser.self, from: value)
                        (UIApplication.shared.delegate as! AppDelegate).user = user
                        self.showNavigation()
                    } catch let error {
                        print("~>There was an error creating object: \(error)")
                        self.showLoginError()
                        return
                    }
                }
                
            } else {
                // create a new user
                DispatchQueue.main.async {
                    let info = self.getUserInfo()
                    var user = CharmUser(first: info.first, last: info.last, email: info.email)
                    user.id = uid
                    
                    do {
                        let data = try FirebaseEncoder().encode(user)
                        Database.database().reference().child(FirebaseStructure.Users).child(uid).setValue(data)
                        (UIApplication.shared.delegate as! AppDelegate).user = user
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
    private func getUserInfo() -> (first: String, last: String, email: String) {
        guard let fullName = Auth.auth().currentUser?.displayName, let email = Auth.auth().currentUser?.email else {
            print("Unable to get name")
            return ("", "", "")
        }
        
        var firstName: String = ""
        var lastName: String = ""
        
        let nameArray = fullName.components(separatedBy: " ")
        
        
        if nameArray.count > 1 {
            firstName = nameArray.first!
            lastName = nameArray.last!
        } else if nameArray.count == 1 {
            firstName = nameArray.first!
            lastName = nameArray.last!
        }
        
        return (firstName, lastName, email)
    }
    
}
