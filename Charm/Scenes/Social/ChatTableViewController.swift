//
//  ChatTableViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 3/7/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit
import Firebase

class ChatTableViewController: UITableViewController {
    
    // MARK: - Properties

    // User object that holds friend list
    let viewModel = ContactsViewModel.shared
    
    // activity view
    let activityView = UIActivityIndicatorView()
    
    // Search controller
    let searchController = UISearchController(searchResultsController: nil)
    
    // MARK: - View Lifecycle Functions

    override func viewDidLoad() {
        super.viewDidLoad()

        // allow view model to refresh tableview
        viewModel.delegate = self
        
        // setup a search bar
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search your friend list..."
        tableView.tableHeaderView = searchController.searchBar
        definesPresentationContext = true
        searchController.searchBar.delegate = self
        
        // setup activity view
        
        if #available(iOS 13.0, *) {
            activityView.style = .large
            activityView.color = .label
        } else {
            activityView.style = .whiteLarge
            activityView.color = .black
        }
        
        activityView.hidesWhenStopped = true
        view.addSubview(activityView)
        
        // Position it at the center of the ViewController.
        activityView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityView.centerYAnchor.constraint(equalTo: view.centerYAnchor)])
        
        showActivity(viewModel.isLoading)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    // MARK: - Private Helper Functions
    
    fileprivate func check(isFriendBusy friend: Friend, showBusyAlert: Bool, completion: @escaping(_ isBusy: Bool) -> Void) {
        let usersRef = Database.database().reference().child(FirebaseStructure.usersLocation)
        var hasCompleted: Bool = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            guard !hasCompleted else { return }
            
            print("~>Request timed out.")
            let errorAlert = UIAlertController(title: "Error", message: "There was an error trying to call \(friend.firstName).  Please check your internet connection and try again.", preferredStyle: .alert)
            errorAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(errorAlert, animated: true, completion: nil)
            completion(true)
        }
        
        let callRef = usersRef.child(friend.id!).child(FirebaseStructure.CharmUser.currentCallLocation)
        callRef.keepSynced(true)
        
        callRef.observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists() {
                print("~>Got call snapshot: \(snapshot)")
                do {
                    let friendCurrentCall = try Call(snapshot: snapshot)
                    // check if user is already on a call
                    if friendCurrentCall.status == .connected && showBusyAlert {
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
        searchController.searchBar.isHidden = viewModel.currentFriends.count == 0
        return isFiltering() ? viewModel.filteredFriends.count : viewModel.currentFriends.count > 0 ? viewModel.currentFriends.count : 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // if a user has no friends, return the empty chat list cell
        if viewModel.currentFriends.count == 0 {
            return tableView.dequeueReusableCell(withIdentifier: CellID.emptyChatList)!
        }
        
        var cell = tableView.dequeueReusableCell(withIdentifier: CellID.chatList, for: indexPath) as! ChatFriendListTableViewCell

        cell = viewModel.configureCell(atIndex: indexPath.row, withCell: cell, filtered: isFiltering())
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard FirebaseModel.shared.charmUser.userProfile.numCredits > 0 else {
            print("~>Not enough credits to make a call.")
            let creditsAlert = UIAlertController(title: "Insufficient Credits", message: "You are out of credits. Please choose a subscription plan if you wish to continue making video calls.", preferredStyle: .alert)
            creditsAlert.addAction(UIAlertAction(title: "Subscribe", style: .default, handler: { (_) in
                self.performSegue(withIdentifier: SegueID.subscriptions, sender: self)
            }))
            creditsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(creditsAlert, animated: true, completion: nil)
            return
        }
        
        if viewModel.currentFriends.count > 0 {
            
            let friend = isFiltering() ? viewModel.filteredFriends[indexPath.row] : viewModel.currentFriends[indexPath.row]
            
            let window = UIApplication.shared.keyWindow!
            let viewActivity = UIActivityIndicatorView(style: .whiteLarge)
            viewActivity.center = window.center
            viewActivity.color = #colorLiteral(red: 0.2799556553, green: 0.2767689228, blue: 0.3593277335, alpha: 1)
            viewActivity.hidesWhenStopped = true
            
            window.addSubview(viewActivity)
            window.bringSubviewToFront(viewActivity)
            
            viewActivity.startAnimating()
            
            check(isFriendBusy: friend, showBusyAlert: false) { (busy) in
                viewActivity.stopAnimating()
                guard !busy else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: { [weak self] in
                        guard let self = self else { return }
                        self.check(isFriendBusy: friend, showBusyAlert: true, completion: { (busy) in
                            guard !busy else { return }
                            self.call(friend)
                        })
                    })
                    return
                }
                self.call(friend)
            }
        }
    }
    
    private func call(_ friend: Friend) {
        let title = "Confirm Call with \(friend.firstName)"
        let message = "One Credit will be deducted from your account.\n\nZero Credits will be deducted from \(friend.firstName)'s account.\n\nThe call will be recorded.\nAbout 15 minutes after the call has ended your data will be loaded into \"My Metrics.\"\n\nIf the call duration is less than 7 minutes, your metrics will not be calculated and credits will not be deducted from your account.  If you experience any difficulties or have any questions, please contact Charm Support by submitting feedback from the \"Settings\" screen."
        let callAlert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        callAlert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        callAlert.addAction(UIAlertAction(title: "Call", style: .cancel, handler: { (_) in
            self.performSegue(withIdentifier: SegueID.videoCall, sender: friend)
        }))
        present(callAlert, animated: true, completion: nil)
    }
    
    // prevent extra table view lines
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(origin: .zero, size: CGSize(width: tableView.frame.width, height: 1)))
        view.backgroundColor = .clear
        return view
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let user = FirebaseModel.shared.charmUser else {
            return "No credits available"
        }
        
        return user.userProfile.numCredits == 0 ? "No credits available" : "Credits Available: " + user.userProfile.credits
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    // MARK: - Segue (start call)
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueID.videoCall, let videoVC = segue.destination as? VideoCallViewController, let friend = sender as? Friend {
            videoVC.friend = friend
            videoVC.myUser = FirebaseModel.shared.charmUser
        } else if segue.identifier == SegueID.friendList, let friendVC = segue.destination as? FriendListTableViewController {
            friendVC.showContacts = false
        }
    }
}

extension ChatTableViewController: UISearchResultsUpdating, UISearchBarDelegate {
    
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.filterSearch(forContacts: true, withText: searchController.searchBar.text!)
    }
    
    fileprivate func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }
    
    internal func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        searchController.searchBar.resignFirstResponder()
        return true
    }
    
    fileprivate func searchBarIsEmpty() -> Bool {
        // Returns true if the text is empty or nil
        return searchController.searchBar.text?.isEmpty ?? true
    }
}

extension ChatTableViewController: TableViewRefreshDelegate {
    func updateTableView() {
        tableView.reloadData()
    }
    
    func showActivity(_ animating: Bool) {
        if animating {
            activityView.startAnimating()
            view.isUserInteractionEnabled = false
        } else  {
            activityView.stopAnimating()
            view.isUserInteractionEnabled = true
        }
    }
}
