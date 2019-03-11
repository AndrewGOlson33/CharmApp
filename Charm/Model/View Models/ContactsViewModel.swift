//
//  ContactsViewModel.swift
//  Charm
//
//  Created by Daniel Pratt on 3/11/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase
import Contacts

class ContactsViewModel {
    
    enum ContactType {
        case Current
        case PendingReceived
        case PendingSent
        case ExistingNotInContacts
        case AddByPhone
    }
    
    // delegate for updating table view
    var delegate: TableViewRefreshDelegate? = nil
    
    // user object
    var user = (UIApplication.shared.delegate as! AppDelegate).user
    
    // compute friends list properties
    var currentFriends: [Friend] {
        guard let thisUser = user, let friendsList = thisUser.friendList, let currentFriends = friendsList.currentFriends else { return [] }
        return currentFriends
    }
    
    var pendingReceived: [Friend] {
        guard let thisUser = user, let friendsList = thisUser.friendList, let pending = friendsList.pendingReceivedApproval else { return [] }
        return pending
    }
    
    var pendingSent: [Friend] {
        guard let thisUser = user, let friendsList = thisUser.friendList, let pending = friendsList.pendingReceivedApproval else { return [] }
        return pending
    }
    
    // contacts
    var contacts: [CNContact] = []
    var notInContacts: [CNContact] = []
//    var inContacts: [CNContact] = []
    
    // friends you can add
    var existingUsers: [Friend] = []
    var usersToInvite: [Friend] = []
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(updatedUser), name: FirebaseNotification.CharmUserDidUpdate, object: nil)
        
        // load contact list
        loadContacts()
        delegate?.updateTableView()
    }
    
    // MARK: - Data Access
    
    func configureCell(atIndex index: Int, withCell cell: FriendListTableViewCell, forType type: ContactType) -> FriendListTableViewCell {
        
        var friend: Friend! = nil
        
        // configure cell properties that vary by type
        switch type {
        case .Current:
            friend = currentFriends[index]
            cell.lblDetail.text = "In friend list"
            cell.btnApprove.isHidden = true
        case .PendingReceived:
            friend = pendingReceived[index]
            cell.lblDetail.text = "Added you from: \(friend.email)"
            cell.btnApprove.setTitle("Approve", for: .normal)
            cell.btnApprove.isHidden = false
        case .PendingSent:
            friend = pendingSent[index]
            cell.lblDetail.text = "Waiting for response."
            cell.btnApprove.isHidden = true
        case .ExistingNotInContacts:
            friend = existingUsers[index]
            cell.lblDetail.text = "In your contacts"
            cell.btnApprove.setTitle("+ Add", for: .normal)
            cell.btnApprove.isHidden = false
        case .AddByPhone:
            friend = usersToInvite[index]
            cell.lblDetail.text = "Invite to Charm"
            cell.btnApprove.setTitle("+ Add", for: .normal)
            cell.btnApprove.isHidden = false
        }
        
        // configure cell data
        cell.lblName.text = "\(friend.firstName) \(friend.lastName)"
        cell.lblEmail.text = friend.email
        
        // configure image
        
        // check to see if contacts has an image
        
        if let image = getPhoto(forFriend: friend) {
            cell.imgProfile.image = image
        } else {
            cell.imgProfile.image = UIImage(named: "icnTempProfile")
            cell.imgProfile.layer.cornerRadius = 0
        }
        
        cell.id = friend.id
        cell.delegate = self
        
        return cell
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
                    self.contacts.append(contact)
                    self.checkFriendList(for: contact)
                })
            } catch let error {
                print("~>Got an error: \(error)")
            }
        }
    }
    
    // Present an alert on top of the navigation controller
    
    fileprivate func presentSettingsAlert() {
        let settingsURL = URL(string: UIApplication.openSettingsURLString)!
        
        DispatchQueue.main.async {
            guard let nav = (UIApplication.shared.delegate as? AppDelegate)?.window?.rootViewController as? UINavigationController else { return }
            let alert = UIAlertController(title: "Permission to Contacts", message: "This app needs access to your contacts in order to help you find people you already know who use Charm.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Go to Settings", style: .default) { _ in
                UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            nav.present(alert, animated: true, completion: nil)
        }
    }
    
    // Check to see if a contact exists already in Charm contact list
    
    fileprivate func checkFriendList(for contact: CNContact) {
        
        var emailAddresses: [String] = []
        
        for email in contact.emailAddresses {
            emailAddresses.append(email.value as String)
        }
        
        guard let contacts = user?.friendList?.currentFriends else { return }
        if contacts.enumerated().contains(where: { (index, friend) -> Bool in
            return emailAddresses.contains(friend.email)
        }) {
//            inContacts.append(contact)
        } else {
            notInContacts.append(contact)
        }
        
    }
    
    fileprivate func getPhoto(forFriend friend: Friend) -> UIImage? {

        for contact in contacts {
            var emailAddresses: [String] = []
            
            for email in contact.emailAddresses {
                emailAddresses.append(email.value as String)
            }
            
            if emailAddresses.contains(friend.email) {
                if contact.imageDataAvailable, let data = contact.thumbnailImageData, let image = UIImage(data: data) {
                    return image
                } else {
                    return nil
                }
            }
        }
        
        return nil
    }
    
    
    // MARK: - Notifications
    
    // updates should be live
    @objc private func updatedUser(_ sender: Notification) {
        guard let updatedUser = sender.object as? CharmUser else { return }
        user = updatedUser
        delegate?.updateTableView()
    }
}

// MARK: - Delegate Function to handle approving a friend request

extension ContactsViewModel: ApproveFriendDelegate {
    
    func approveFriendRequest(withId id: String) {
        // first move friend from received to current friends
        
        guard var user = user else { return }
        
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
            
            
        } catch let error {
            print("~>Got an error: \(error)")
            return
        }
        
        // update table
        delegate?.updateTableView()
        
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
