//
//  CharmLaunchpointViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 4/23/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit
import Contacts
import Firebase

class CharmLaunchpointViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var viewActivityContainer: UIView!
    @IBOutlet weak var viewActivity: UIActivityIndicatorView!
    
    // MARK: - View Lifecycle Functions

    override func viewDidLoad() {
        super.viewDidLoad()
        print("~>View did load")
        viewActivityContainer.layer.cornerRadius = 16

        startActivity()
        
        let status = CNContactStore.authorizationStatus(for: .contacts)
        let store = CNContactStore()
        if status == .notDetermined {
            store.requestAccess(for: .contacts) {  (granted, error) in
                print("~>Access granted: \(granted)")
            }
        }
        
        // check if user exists
        guard let user = Auth.auth().currentUser else {
            // load login screen
            stopActivity()
            showLogin()
            return
        }
        
        user.reload { (error) in
            if let error = error {
                print("~>Error reloading user: \(error)")
            }
            
            user.getIDTokenForcingRefresh(true, completion: { (result, error) in
                guard error == nil else {
                    self.stopActivity()
                    self.showLogin()
                    return
                }
                
                user.getIDTokenResult(forcingRefresh: true) { (result, error) in
                    self.stopActivity()
                    if let _ = error {
                        print("~>Need to stay here.")
                        self.showAlert(withTitle: "Expired", andMessage: "Your login has expired.  Please login again.")
                        return
                    } else {
                        guard let uid = Auth.auth().currentUser?.uid else {
                            print("~>There was an error getting the user's UID.")
                            self.showAlert(withTitle: "Expired", andMessage: "Your login has expired.  Please login again.")
                            return
                        }
                        
                        self.loadUser(withUID: uid)
                    }
                }
            })

        }
        
        
        
    }
    
    // MARK: - Activity Helper Functions
    
    private func startActivity() {
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
        }
    }
    
    // MARK: - Segue Functions
    
    private func showLogin() {
        DispatchQueue.main.async {
            let nav = self.storyboard?.instantiateViewController(withIdentifier: StoryboardID.login)
            let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
            // clear out any calls as needed
            appDelegate.window?.rootViewController = nav
            appDelegate.window?.makeKeyAndVisible()
        }
    }
    
    private func showNavigation() {
        DispatchQueue.main.async {
            let nav = self.storyboard?.instantiateViewController(withIdentifier: StoryboardID.navigationHome)
            let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
            // clear out any calls as needed
            appDelegate.window?.rootViewController = nav
            appDelegate.window?.makeKeyAndVisible()
        }
    }
    
    // MARK: - Load User Function
    
    private func loadUser(withUID uid: String) {
        // read user
        Database.database().reference().child(FirebaseStructure.usersLocation).child(uid).observeSingleEvent (of: .value) { (snapshot) in
            if snapshot.exists() {
                // setup a user item
                DispatchQueue.main.async {
                    do {
                        let user = try CharmUser(snapshot: snapshot)
                        FirebaseModel.shared.charmUser = user
                        self.showNavigation()
                    } catch let error {
                        print("~>There was an error creating object: \(error)")
                        self.showAlert(withTitle: "Expired", andMessage: "Your login has expired.  Please login again.")
                        return
                    }
                }
                
            } else {
                self.showAlert(withTitle: "Expired", andMessage: "Your login has expired.  Please login again.")
                return
            }
        }
    }
    
    // MARK: - Private Helper Functions
    
    private func showAlert(withTitle title: String, andMessage message:String, showLogin: Bool = true) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
            if showLogin { self.showLogin() }
        }))
        self.present(alert, animated: true)
    }

}
