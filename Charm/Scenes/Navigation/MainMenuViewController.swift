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
//        testFirebase()
    }
    
    // TODO: Delete this method
    
    private func testFirebase() {
        // Saving new data
        var newUser = CharmUser(first: "Daniel", last: "Pratt", email: "daniel@blaumagier.com")
        let ref = Database.database().reference().child("testData").childByAutoId()
        newUser.id = ref.key
        let data = try! FirebaseEncoder().encode(newUser)
        ref.setValue(data)
        
//        // Loading data
//        Database.database().reference().child("testData").child("-L_IyB77EhS2XvC_AZCO").observeSingleEvent(of: .value) { (snapshot) in
//            guard let value = snapshot.value else { return }
//            do {
//                let user = try FirebaseDecoder().decode(CharmUser.self, from: value)
//                print(user)
//            } catch let error {
//                print("~>There was an error retreiving data: \(error)")
//                print("~>Got value: \(value)")
//            }
//        }
    }
    
    // MARK: - Button Handling
    
    @IBAction func chatButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: SegueID.FriendList, sender: self)
    }

}
