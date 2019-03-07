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
                guard let results = snapshot.value as? [AnyHashable:Any], let first = results.first?.value else {
                    alert.title = "Not Found"
                    alert.message = "The e-mail address you entered was not found.  Please try again."
                    self.present(alert, animated: true, completion: nil)
                    return
                }
                
                // get friend user setup, and add self to their incoming friends
                var friendUser = try! FirebaseDecoder().decode(CharmUser.self, from: first)
                
                // create a friend list if needed
                if friendUser.friendList == nil {
                    friendUser.friendList = FriendList()
                } else if let myList = self.friends {
                    // check to make sure this user is not already in our friend's list
                    if let current = myList.currentFriends {
                        for friend in current {
                            if friend.id == friendUser.id {
                                alert.title = "Friend Exists"
                                alert.message = "The user you are trying to add is already in your contact list."
                                self.present(alert, animated: true, completion: nil)
                                return
                            }
                        }
                    }
                    
                    if let sent = myList.pendingSentApproval {
                        for friend in sent {
                            if friend.id == friendUser.id {
                                alert.title = "Friend Request Already Sent"
                                alert.message = "You have already sent a request to this user."
                                self.present(alert, animated: true, completion: nil)
                                return
                            }
                        }
                    }
                    
                    if let received = myList.pendingReceivedApproval {
                        for friend in received {
                            if friend.id == friendUser.id {
                                alert.title = "Accept Request"
                                alert.message = "This user has already sent you a friend request.  Please accept their request to add as a friend."
                                self.present(alert, animated: true, completion: nil)
                                return
                            }
                        }
                    }
                }
                let meAsFriend = Friend(id: self.myUser.id!, first: self.myUser.userProfile.firstName, last: self.myUser.userProfile.lastName, email: self.myUser.userProfile.email)
                friendUser.friendList!.pendingReceivedApproval?.append(meAsFriend)
                
                // set friend user as a friend item, and add them to user's sent requests
                let friend = Friend(id: friendUser.id!, first: friendUser.userProfile.firstName, last: friendUser.userProfile.lastName, email: friendUser.userProfile.email)
                if self.myUser.friendList == nil { self.myUser.friendList = FriendList() }
                self.myUser.friendList!.pendingSentApproval?.append(friend)
                
                
                do {
                    let myData = try FirebaseEncoder().encode(friendUser.friendList!.pendingReceivedApproval)
                    let friendData = try FirebaseEncoder().encode(self.myUser.friendList!.pendingSentApproval)
                    
                    // Write data to firebase
                    
                    ref.child(FirebaseStructure.Users).child(friendUser.id!).child(FirebaseStructure.CharmUser.Friends).child(FirebaseStructure.CharmUser.FriendList.PendingReceivedApproval).setValue(myData)
                    
                    ref.child(FirebaseStructure.Users).child(self.myUser.id!).child(FirebaseStructure.CharmUser.Friends).child(FirebaseStructure.CharmUser.FriendList.PendingSentApproval).setValue(friendData)
                    
                    alert.title = "Sent Request"
                    alert.message = "Your friend request has been sent.  Once the request has been approved by your friend, they will show up on your friends list."
                    self.present(alert, animated: true, completion: nil)
                } catch let error {
                    print("~>Got a bloody error: \(error)")
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
        return friends == nil ? 0 : friends?.currentFriends?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return UITableViewCell()
    }

}
