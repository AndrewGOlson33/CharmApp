//
//  FriendListTableViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 3/7/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase
import Contacts

class FriendListTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    // Search controller
    let searchController = UISearchController(searchResultsController: nil)
    
    // User object that holds friend list
    var user: CharmUser!
    
    // add mode properties
    var inAddMode: Bool = false
    var contacts: [CNContact] = []
    var notInContacts: [CNContact] = []
    var inContacts: [CNContact] = []
    
    // MARK: - View Lifecycle Functions

    override func viewDidLoad() {
        super.viewDidLoad()

        // load up the user to build friend list from
        DispatchQueue.main.async {
            self.user = (UIApplication.shared.delegate as! AppDelegate).user
            self.tableView.reloadData()
        }
        
        // setup a search bar
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search your friend list..."
        tableView.tableHeaderView = searchController.searchBar
//        definesPresentationContext = true
        searchController.searchBar.delegate = self
        
        // Load Contact list
        loadContacts()
        
    }
    
    // MARK: - Private Helper Functions
    
    private func loadContacts() {
        
        // make sure user hasn't denied access
        let status = CNContactStore.authorizationStatus(for: .contacts)
        if status == .denied || status == .restricted {
            // present alert
            presentSettingsAlert()
        }
        
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { (granted, error) in
            
            // make sure access is granted
            guard granted else {
                print("~>There was an error getting authorization: \(String(describing: error))")
                self.presentSettingsAlert()
                return
            }
            
            // format request
            let request = CNContactFetchRequest(keysToFetch: [CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
                                                              CNContactPhoneNumbersKey as CNKeyDescriptor,
                                                              CNContactEmailAddressesKey as CNKeyDescriptor,
                                                              CNContactImageDataKey as CNKeyDescriptor,
                                                              CNContactThumbnailImageDataKey as CNKeyDescriptor,
                                                              CNContactImageDataAvailableKey as CNKeyDescriptor
                                                              ])
            
            // do request
            do {
                try store.enumerateContacts(with: request, usingBlock: { (contact, stop) in
                    let  name = CNContactFormatter.string(from: contact, style: .fullName)
                    print("~>Got contact with name: \(String(describing: name)), phone numbers: \(contact.phoneNumbers), email addresses: \(contact.emailAddresses), and image data: \(String(describing: contact.imageData)), and thumbnail data: \(String(describing: contact.thumbnailImageData))")
                })
            } catch let error {
                print("~>Got an error: \(error)")
            }
        }
    }
    
    // Present an error when unable to get authorization for contacts
    
    private func presentSettingsAlert() {
        let settingsURL = URL(string: UIApplication.openSettingsURLString)!
        
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Permission to Contacts", message: "This app needs access to contacts in order to ...", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Go to Settings", style: .default) { _ in
//                UIApplication.shared.openURL(settingsURL)
                UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self.present(alert, animated: true)
        }
    }

    // MARK: - Table view data source
// Comment out for now
//    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        switch section {
//        case 0:
//            return "Friends"
//        case 1:
//            return "Received Friend Request"
//        default:
//            return "Sent Friend Requests"
//        }
//    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        guard let friends = user?.friendList else { return 0 }
        switch section {
        case 0:
            return friends.currentFriends?.count ?? 0
        case 1:
            return friends.pendingReceivedApproval?.count ?? 0
        default:
            return friends.pendingSentApproval?.count ?? 0
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellID.FriendList, for: indexPath) as! FriendListTableViewCell
        guard let friends = user?.friendList else { fatalError("~>Unable to load friends") }
        
        // get friend object
        var friend: Friend!
        var detail: String = ""
        switch indexPath.section {
        case 0:
            friend = friends.currentFriends![indexPath.row]
            detail = "In friend list"
        case 1:
            friend = friends.pendingReceivedApproval![indexPath.row]
            detail = "Added you from: \(friend.email)"
        default:
            friend = friends.pendingSentApproval![indexPath.row]
            detail = "Waiting for response."
        }
        
        cell.lblName.text = "\(friend.firstName) \(friend.lastName)"
        cell.lblEmail.text = friend.email
        cell.lblDetail.text = detail
        
        // setup approval delegate
        cell.btnApprove.isHidden = indexPath.section == 1 ? false : false
        cell.id = friend.id
        cell.delegate = self

        return cell
    }

}

// MARK: - Delegate Function to handle approving a friend request

extension FriendListTableViewController: ApproveFriendDelegate {
    
    func approveFriendRequest(withId id: String) {
        // first move friend from received to current friends
        let received = user.friendList!.pendingReceivedApproval
        if user.friendList?.currentFriends == nil { user.friendList?.currentFriends = [] }
        
        for (index, friend) in received!.enumerated() {
            if friend.id == id {
                user.friendList?.currentFriends?.append(friend)
                user.friendList!.pendingReceivedApproval?.remove(at: index)
                print("~>Removed item.")
                break
            }
        }
        
        // write data to firebase
        
        do {
            let current = try FirebaseEncoder().encode(user.friendList?.currentFriends!)
            let received = try FirebaseEncoder().encode(user.friendList!.pendingReceivedApproval!)
            
            Database.database().reference().child(FirebaseStructure.Users).child(user.id!).child(FirebaseStructure.CharmUser.Friends).child(FirebaseStructure.CharmUser.FriendList.CurrentFriends).setValue(current)
            Database.database().reference().child(FirebaseStructure.Users).child(user.id!).child(FirebaseStructure.CharmUser.Friends).child(FirebaseStructure.CharmUser.FriendList.PendingReceivedApproval).setValue(received)
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            
            
        } catch let error {
            print("~>Got an error: \(error)")
            return
        }
        
        // update table
        
        // finally move user from sent to current friends on friend's friend list'
        guard let myID = user.id else { return }
        Database.database().reference().child(FirebaseStructure.Users).child(id).observeSingleEvent(of: .value) { (snapshot) in
            guard let value = snapshot.value else { return }
            // get the user object
            var friendUser = try! FirebaseDecoder().decode(CharmUser.self, from: value)
            if friendUser.friendList == nil { friendUser.friendList = FriendList() }
            let pending = friendUser.friendList?.pendingSentApproval
            if friendUser.friendList?.currentFriends == nil { friendUser.friendList?.currentFriends = [] }
        
            if pending == nil { return }
            var meFriend: Friend!
            for (index, user) in pending!.enumerated() {
                if user.id == myID {
                    meFriend = user
                    friendUser.friendList!.pendingSentApproval!.remove(at: index)
                    friendUser.friendList?.currentFriends?.append(meFriend)
                    break
                }
            }
            
            // write changes to firebase
            do {
                let current = try FirebaseEncoder().encode(friendUser.friendList!.currentFriends!)
                let sent = try FirebaseEncoder().encode(friendUser.friendList!.pendingSentApproval!)
                Database.database().reference().child(FirebaseStructure.Users).child(id).child(FirebaseStructure.CharmUser.Friends).child(FirebaseStructure.CharmUser.FriendList.CurrentFriends).setValue(current)
                Database.database().reference().child(FirebaseStructure.Users).child(id).child(FirebaseStructure.CharmUser.Friends).child(FirebaseStructure.CharmUser.FriendList.PendingSentApproval).setValue(sent)
            } catch let error {
                print("~>Got an error: \(error)")
            }
        }
    }
    
}

// MARK: - Search Delegate Functions

extension FriendListTableViewController: UISearchResultsUpdating, UISearchBarDelegate {
    
    func updateSearchResults(for searchController: UISearchController) {
//        filterContentForSearchText(searchController.searchBar.text!)
    }
    
    fileprivate func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }
    
    fileprivate func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        searchController.searchBar.resignFirstResponder()
        return true
    }
    
    fileprivate func searchBarIsEmpty() -> Bool {
        // Returns true if the text is empty or nil
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
}
