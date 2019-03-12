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

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.currentFriends.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: CellID.ChatList, for: indexPath)

        cell = viewModel.configureCell(atIndex: indexPath.row, withCell: cell)

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let friend = viewModel.currentFriends[indexPath.row]
        performSegue(withIdentifier: SegueID.VideoCall, sender: friend)
    }
    
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
