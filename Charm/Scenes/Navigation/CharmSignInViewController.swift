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
                // TODO: - Handle Bad Results
                guard let uid = Auth.auth().currentUser?.uid else { fatalError("~>No uid with existing user") }
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

}

// MARK: - Sign in Delegate

extension CharmSignInViewController: FUIAuthDelegate {
    
    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
        print("~>Got a result: \(authDataResult.debugDescription)")
        
        // TODO: - Handle Bad Results
        guard let result = authDataResult else { fatalError("~>Bad result") }
        let uid = result.user.uid
        loadUser(withUID: uid)
    }
    
    // MARK: - Load User
    
    private func loadUser(withUID uid: String) {
        // read user
        Database.database().reference().child(FirebaseStructure.Users).child(uid).observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists() {
                // setup a user item
                guard let value = snapshot.value else { fatalError("~>Unable to get value from snapshot") }
                DispatchQueue.main.async {
                    do {
                        let user = try FirebaseDecoder().decode(CharmUser.self, from: value)
                        (UIApplication.shared.delegate as! AppDelegate).user = user
                        self.showNavigation()
                    } catch let error {
                        // TODO: - Error handling
                        fatalError("~>There was an error creating object: \(error)")
                    }
                }
                
            } else {
                // create a new user
                DispatchQueue.main.async {
                    let info = self.getUserInfo()
                    var user = CharmUser(first: info.first, last: info.last, email: info.email)
                    user.id = uid
                    // TODO: - Add some error handling
                    let data = try! FirebaseEncoder().encode(user)
                    Database.database().reference().child(FirebaseStructure.Users).child(uid).setValue(data)
                    (UIApplication.shared.delegate as! AppDelegate).user = user
                    self.showNavigation()
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
