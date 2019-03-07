//
//  ChatTableViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 3/7/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

class ChatTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    var friends: FriendList? = nil
    var myUser: CharmUser!
    
    // MARK: - View Lifecycle Functions

    override func viewDidLoad() {
        super.viewDidLoad()

        DispatchQueue.main.async {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            self.myUser = appDelegate.user
            self.friends = appDelegate.user.friendList
            self.tableView.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Setup listener to update when there are changes to user
        NotificationCenter.default.addObserver(self, selector: #selector(charmUserUpdated(_:)), name: FirebaseNotification.CharmUserDidUpdate, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Tear down listeners
        NotificationCenter.default.removeObserver(self, name: FirebaseNotification.CharmUserDidUpdate, object: nil)
    }
    
    // MARK: - Button Handling
    
    @IBAction func addFriendTapped(_ sender: Any) {
        let addFriendAlert = UIAlertController(title: "Add a Friend", message: "Enter the e-mail address for the friend you want to add.", preferredStyle: .alert)
        addFriendAlert.addTextField { (emailTF) in
            emailTF.placeholder = "enter email address here"
            emailTF.keyboardType = .emailAddress
        }
        addFriendAlert.addAction(UIAlertAction(title: "Add", style: .default, handler: { (_) in
            let alert = UIAlertController(title: "", message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            guard let email = addFriendAlert.textFields?.first?.text else {
                // create another alert
                alert.title = "Invalid Email"
                alert.message = "Please enter a valid email before selecting add."
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            let ref = Database.database().reference()
            let emailQuery = ref.child(FirebaseStructure.Users).queryOrdered(byChild: "userProfile/email").queryEqual(toValue: email).queryLimited(toFirst: 1)
            emailQuery.observeSingleEvent(of: .value) { (snapshot) in
                guard let results = snapshot.value as? [AnyHashable:Any], let first = results.first?.value as? [String:Any] else {
                    alert.title = "Not Found"
                    alert.message = "The e-mail address you entered was not found.  Please try again."
                    self.present(alert, animated: true, completion: nil)
                    return
                }
                
                guard let id = first[FirebaseStructure.Friend.ID] as? String, let profile = first[FirebaseStructure.CharmUser.Profile] as? [String:Any] else {
                    alert.title = "Error"
                    alert.message = "There was a fatal error trying to add an existing user (No ID found).  Please contact us to resolve the issue."
                    self.present(alert, animated: true, completion: nil)
                    return
                }

                let firstName = profile[FirebaseStructure.Friend.FirstName] as? String ?? ""
                let lastName = profile[FirebaseStructure.Friend.LastName] as? String ?? ""
                let friendEmail = profile[FirebaseStructure.Friend.Email] as? String ?? email

                let friend = Friend(id: id, first: firstName, last: lastName, email: friendEmail)
                let meAsFriend = Friend(id: self.myUser.id!, first: self.myUser.userProfile.firstName, last: self.myUser.userProfile.lastName, email: self.myUser.userProfile.email)
                do {
                    let data = try FirebaseEncoder().encode(friend)
                    let myData = try FirebaseEncoder().encode(meAsFriend)
                    ref.child(FirebaseStructure.Users).child(self.myUser.id!).child(FirebaseStructure.CharmUser.Friends).child(FirebaseStructure.CharmUser.FriendList.PendingSentApproval).setValue(data)
                    ref.child(FirebaseStructure.Users).child(id).child(FirebaseStructure.CharmUser.Friends).child(FirebaseStructure.CharmUser.FriendList.PendingReceivedApproval).setValue(myData)
                } catch let error {
                    print("~>There was an error creating the friend object: \(error)")
                    alert.title = "Error"
                    alert.message = "There was a fatal error trying to add an existing user (No ID found).  Please contact us to resolve the issue."
                    self.present(alert, animated: true, completion: nil)
                    return
                }
            }
        }))
        addFriendAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(addFriendAlert, animated: true, completion: nil)
    }
    
    // MARK: - Notification Handling
    
    // When user is updated, see if there are new friends
    // If so, load them
    @objc private func charmUserUpdated(_ sender: Notification) {
        guard let user = sender.object as? CharmUser else { return }
        if let friendlist = user.friendList, let loadedFriends = friends, friendlist.count != loadedFriends.count {
            friends = friendlist
            tableView.reloadData()
        } else if let friendList = user.friendList, friends == nil {
            friends = friendList
            tableView.reloadData()
        } else if user.friendList == nil {
            friends = nil
            tableView.reloadData()
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return friends == nil ? 0 : friends?.currentFriends.count ?? 0
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
