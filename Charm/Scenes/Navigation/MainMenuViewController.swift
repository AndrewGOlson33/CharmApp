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
        
        let ref = Database.database().reference()
        let emailQuery = ref.child(FirebaseStructure.Users).queryOrdered(byChild: "userProfile/email").queryEqual(toValue: "daniel@blaumagier.com")
        emailQuery.observeSingleEvent(of: .value) { (snapshot) in
            print("~>Did a query: \(String(describing: snapshot.value))")
        }
    }
    
    
    // MARK: - Button Handling
    
    @IBAction func chatButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: SegueID.FriendList, sender: self)
    }

}
