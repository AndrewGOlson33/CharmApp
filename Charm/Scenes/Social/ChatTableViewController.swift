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

    // User object that holds friend list
    let viewModel = ContactsViewModel()
    
    // MARK: - View Lifecycle Functions

    override func viewDidLoad() {
        super.viewDidLoad()

        // allow view model to refresh tableview
        viewModel.delegate = self
    }
    
    // MARK: - Private Helper Functions
    
    fileprivate func check(isFriendBusy friend: Friend, completion: @escaping(_ isBusy: Bool) -> Void) {
        let usersRef = Database.database().reference().child(FirebaseStructure.Users)
        var hasCompleted: Bool = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            guard !hasCompleted else { return }
            
            print("~>Request timed out.")
            let errorAlert = UIAlertController(title: "Error", message: "There was an error trying to call \(friend.firstName).  Please check your internet connection and try again.", preferredStyle: .alert)
            errorAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(errorAlert, animated: true, completion: nil)
            completion(true)
        }
        usersRef.child(friend.id!).child(FirebaseStructure.CharmUser.Call).observeSingleEvent(of: .value) { (snapshot) in
            if let value = snapshot.value, !(value is NSNull) {
                print("~>Got value: \(value)")
                do {
                    let friendCurrentCall = try FirebaseDecoder().decode(Call.self, from: value)
                    // check if user is already on a call
                    if friendCurrentCall.status == .connected {
                        let busyAlert = UIAlertController(title: "Busy", message: "\(friend.firstName) is currently on another call.  Please try calling later.", preferredStyle: .alert)
                        busyAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(busyAlert, animated: true, completion: nil)
                        completion(true)
                        hasCompleted = true
                    } else {
                        completion(false)
                        hasCompleted = true
                    }
                } catch let error {
                    print("~>There was an error trying to determin the friend's call status: \(error)")
                    let errorAlert = UIAlertController(title: "Error", message: "There was an error trying to call \(friend.firstName).  Please try again later.", preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(errorAlert, animated: true, completion: nil)
                    completion(true)
                    hasCompleted = true
                }
            } else {
                completion(false)
                hasCompleted = true
            }
        }
        
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.currentFriends.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: CellID.ChatList, for: indexPath) as! ChatFriendListTableViewCell

        cell = viewModel.configureCell(atIndex: indexPath.row, withCell: cell)

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let friend = viewModel.currentFriends[indexPath.row]
        
        check(isFriendBusy: friend) { (busy) in
            guard !busy else { return }
            self.performSegue(withIdentifier: SegueID.VideoCall, sender: friend)
        }
        
        
    }
    
    // prevent extra table view lines
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(origin: .zero, size: CGSize(width: tableView.frame.width, height: 1)))
        view.backgroundColor = .clear
        return view
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }
    
    // MARK: - Segue (start call)
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueID.VideoCall, let videoVC = segue.destination as? VideoCallViewController, let friend = sender as? Friend {
            videoVC.friend = friend
            videoVC.myUser = viewModel.user!
        }
    }

}

extension ChatTableViewController: TableViewRefreshDelegate {
    
    func updateTableView() {
        tableView.reloadData()
    }
    
}
