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
        
        // TODO: - Delete this test method
        testFirebase()
    }
    
    // TODO: Delete this method
    
    private func testFirebase() {
        Database.database().reference().child("setupTest").child("user").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value else { return }
            do {
                let user = try FirebaseDecoder().decode(User.self, from: value)
                print(user)
            } catch let error {
                print("~>There was an error: \(error)")
            }
        })
    }
    
    // MARK: - Button Handling
    
    @IBAction func chatButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: SegueID.FriendList, sender: self)
    }

}
