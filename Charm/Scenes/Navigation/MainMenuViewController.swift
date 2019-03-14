//
//  MainMenuViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 3/6/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

class MainMenuViewController: UIViewController {
    
    // MARK: - Properties
    
    var isFirebaseConnected: Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup loss of internet observer
        setupConnetionObserver()
        
        // Setup user observer
        setupUser()
    }
    
    // MARK: - Private Setup Functions
    
    fileprivate func setupConnetionObserver() {
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { connected in
            if let boolean = connected.value as? Bool, boolean == true {
                print("~>Connected")
                if !self.isFirebaseConnected {
                    self.showConnectionAlert()
                }
            } else {
                print("~>Not connected")
                self.showConnectionAlert()
            }
        })
    }
    
    fileprivate func showConnectionAlert() {
        DispatchQueue.main.async {
            self.isFirebaseConnected = !self.isFirebaseConnected
            let title = self.isFirebaseConnected ? "Connection Restored" : "Connection Lost"
            let message = self.isFirebaseConnected ? "Connection to the database server has been restored." : "Lost connection to databse server.  Please check your internet connection."
            
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.navigationController?.present(alert, animated: true, completion: nil)
        }
    }
    
    fileprivate func setupUser() {
        Database.database().reference().child(FirebaseStructure.Users).child(Auth.auth().currentUser!.uid).observe(.value) { (snapshot) in
            guard let value = snapshot.value else { return }
            DispatchQueue.main.async {
                do {
                    let user = try FirebaseDecoder().decode(CharmUser.self, from: value)
                    (UIApplication.shared.delegate as! AppDelegate).user = user
                    // Post a notification that the user changed, along with the user obejct
                    NotificationCenter.default.post(name: FirebaseNotification.CharmUserDidUpdate, object: user)
                    // If there is a call, post a notification about that call
                    if let call = user.currentCall {
                        if call.status == .incoming {
                            NotificationCenter.default.post(name: FirebaseNotification.CharmUserIncomingCall, object: call)
                            let alert = UIAlertController(title: "Incoming Call", message: "You have an incoming call.", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Accept", style: .default, handler: { (_) in
                                self.setupIncoming(call: call)
                            }))
                            alert.addAction(UIAlertAction(title: "Ignore", style: .cancel, handler: nil))
                            self.navigationController?.present(alert, animated: true, completion: nil)
                        }
                    }
                } catch let error {
                    print("~>There was an error: \(error)")
                    return
                }
            }
        }
    }
    
    fileprivate func setupIncoming(call: Call) {
        DispatchQueue.main.async {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let myUser = appDelegate.user!
            guard let friend = myUser.friendList?.currentFriends?.first(where: { (friend) -> Bool in
                friend.id! == call.fromUserID
            }) else {
                // TODO: - Error handling
                return
            }
            
            let callVC = self.storyboard?.instantiateViewController(withIdentifier: StoryboardID.VideoCall) as! VideoCallViewController
            callVC.myUser = myUser
            callVC.friend = friend
            callVC.kSessionId = call.sessionID
            
            self.navigationController?.pushViewController(callVC, animated: true)
        }
    }
    
    
    // MARK: - Button Handling
    
    @IBAction func chatButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: SegueID.FriendList, sender: self)
    }

}
