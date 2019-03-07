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

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // Test query existing user by email address
        
//        let ref = Database.database().reference()
//        let emailQuery = ref.child(FirebaseStructure.Users).queryOrdered(byChild: "userProfile/email").queryEqual(toValue: "daniel@blaumagier.com")
//        emailQuery.observeSingleEvent(of: .value) { (snapshot) in
//            print("~>Did a query: \(String(describing: snapshot.value))")
//        }
        
        // Setup user observer
        Database.database().reference().child(FirebaseStructure.Users).child(Auth.auth().currentUser!.uid).observe(.value) { (snapshot) in
            guard let value = snapshot.value else { return }
            DispatchQueue.main.async {
                do {
                    let user = try FirebaseDecoder().decode(CharmUser.self, from: value)
                    (UIApplication.shared.delegate as! AppDelegate).user = user
                    // Post a notification that the user changed, along with the user obejct
                    NotificationCenter.default.post(name: FirebaseNotification.CharmUserDidUpdate, object: user)
                } catch let error {
                    print("~>There was an error: \(error)")
                    return
                }
            }
        }
    }
    
    
    // MARK: - Button Handling
    
    @IBAction func chatButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: SegueID.FriendList, sender: self)
    }

}
