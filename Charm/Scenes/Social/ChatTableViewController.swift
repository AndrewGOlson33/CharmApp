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
    
    // MARK: - Notification Handling
    
    // When user is updated, see if there are new friends
    // If so, load them
    @objc private func charmUserUpdated(_ sender: Notification) {
        guard let user = sender.object as? CharmUser else { return }
        myUser = user
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
        let cell = tableView.dequeueReusableCell(withIdentifier: CellID.ChatList, for: indexPath)

        guard let friend = friends?.currentFriends?[indexPath.row] else { return cell }
        
        cell.textLabel?.text = "\(friend.firstName) \(friend.lastName)"
        cell.detailTextLabel?.text = friend.email

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let friend = friends?.currentFriends?[indexPath.row] else { return }
        performSegue(withIdentifier: SegueID.VideoCall, sender: friend)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueID.VideoCall, let videoVC = segue.destination as? VideoCallViewController, let friend = sender as? Friend {
            videoVC.friend = friend
            videoVC.myUser = myUser
        }
    }

}
