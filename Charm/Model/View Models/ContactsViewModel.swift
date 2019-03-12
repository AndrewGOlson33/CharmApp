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
import MessageUI

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
        guard let thisUser = user, let friendsList = thisUser.friendList, let pending = friendsList.pendingSentApproval else { return [] }
        return pending
    }
    
    // contacts
    var contacts: [CNContact] = []
    var notInContacts: [CNContact] = []
    
    // friends you can add
    var existingUsers: [Friend] = [] {
        didSet {
            existingUsers.sort { (lhs, rhs) -> Bool in
                return lhs.lastName < rhs.lastName
            }
        }
    }
    var usersToInvite: [Friend] = [] {
        didSet {
            usersToInvite.sort { (lhs, rhs) -> Bool in
                return lhs.lastName < rhs.lastName
            }
        }
    }
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(updatedUser), name: FirebaseNotification.CharmUserDidUpdate, object: nil)
        
        // load contact list
        loadContacts()
        delegate?.updateTableView()
        setupAddFriendsArrays()
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
            cell.addMethod = .Approval
        case .PendingSent:
            friend = pendingSent[index]
            cell.lblDetail.text = "Waiting for response."
            cell.btnApprove.isHidden = false
            cell.btnApprove.setTitle("Pending", for: .normal)
        case .ExistingNotInContacts:
            friend = existingUsers[index]
            cell.lblDetail.text = "In your contacts"
            cell.btnApprove.setTitle("+ Add", for: .normal)
            cell.btnApprove.isHidden = false
            cell.addMethod = .Email
        case .AddByPhone:
            friend = usersToInvite[index]
            cell.lblDetail.text = "Invite to Charm"
            cell.btnApprove.setTitle("+ Add", for: .normal)
            cell.btnApprove.isHidden = false
            cell.addMethod = .Phone
        }
        
        // configure cell data
        cell.lblName.text = "\(friend.firstName) \(friend.lastName)"
        cell.lblEmail.text = type == .AddByPhone ? friend.phone! : friend.email
        
        // configure image
        
        // check to see if contacts has an image
        
        if let image = getPhoto(forFriend: friend) {
            cell.imgProfile.image = image
        } else {
            cell.imgProfile.image = UIImage(named: "icnTempProfile")
        }
        
        cell.friend = friend
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
    // If not, add it to the not in contacts list to use
    // in the add user section
    fileprivate func checkFriendList(for contact: CNContact) {
        
        var emailAddresses: [String] = []
        
        for email in contact.emailAddresses {
            emailAddresses.append(email.value as String)
        }
        
        guard let contacts = user?.friendList?.currentFriends else {
            notInContacts.append(contact)
            return
        }
        if !contacts.enumerated().contains(where: { (index, friend) -> Bool in
            return emailAddresses.contains(friend.email)
        }) {
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
    
    // setup the arrays for adding contacts
    fileprivate func setupAddFriendsArrays() {
        // only loop through contacts we know are not in the user's friend list
        for contact in notInContacts {
            var found: Bool = false
            
            // TODO: - Prevent showing the user's own email
            
            for email in contact.emailAddresses {
                let value = email.value as String
                let ref = Database.database().reference()
                let emailQuery = ref.child(FirebaseStructure.Users).queryOrdered(byChild: "userProfile/email").queryEqual(toValue: value).queryLimited(toFirst: 1)
                emailQuery.observeSingleEvent(of: .value) { (snapshot) in
                    if let results = snapshot.value as? [AnyHashable:Any], let first = results.first?.value {
                        found = true
                        let friendUser = try! FirebaseDecoder().decode(CharmUser.self, from: first)
                        let friend = Friend(id: friendUser.id!, first: friendUser.userProfile.firstName, last: friendUser.userProfile.lastName, email: friendUser.userProfile.email)
                        self.existingUsers.append(friend)
                    }
                }
            }
            
            if !found {
                let firstName = contact.givenName
                let lastName = contact.familyName
                var emailAddress = ""
                if let emailItem = contact.emailAddresses.first {
                    emailAddress = emailItem.value as String
                }
                let phone = contact.phoneNumbers.first?.value.stringValue ?? ""
                guard !firstName.isEmpty && !phone.isEmpty else { continue }
                var friend = Friend(id: "N/A", first: firstName, last: lastName, email: emailAddress)
                friend.phone = phone
                usersToInvite.append(friend)
            }
        }
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

extension ContactsViewModel: FriendManagementDelegate {
    
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
    
    // MARK: - Private Helper Functions that do the heavy lifting for friend adding
    
    func sendEmailRequest(toFriend friend: Friend) {
        // setup views for displaying error alerts
        let navVC = (UIApplication.shared.delegate as! AppDelegate).window!.rootViewController as! UINavigationController
        let alert = UIAlertController(title: "", message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))

        let ref = Database.database().reference()
        let emailQuery = ref.child(FirebaseStructure.Users).queryOrdered(byChild: "userProfile/email").queryEqual(toValue: friend.email).queryLimited(toFirst: 1)
        emailQuery.observeSingleEvent(of: .value) { (snapshot) in
            guard let results = snapshot.value as? [AnyHashable:Any], let first = results.first?.value else {
                alert.title = "Unable to Send Request"
                alert.message = "The request not able to be sent at this time.  Please try again later."
                navVC.present(alert, animated: true, completion: nil)
                return
            }

            // get friend user setup, and add self to their incoming friends
            var friendUser = try! FirebaseDecoder().decode(CharmUser.self, from: first)

            // create a friend list if needed
            // if the user already has a list, make sure we don't have
            // a pending reques from them already
            if friendUser.friendList == nil {
                friendUser.friendList = FriendList()
            } else if let myList = self.user!.friendList, let received = myList.pendingReceivedApproval {
                for friend in received {
                if friend.id == friendUser.id {
                    alert.title = "Accept Request"
                    alert.message = "This user has already sent you a friend request.  Please accept their request to add as a friend."
                    navVC.present(alert, animated: true, completion: nil)
                    return
                    }
                }
            }
        
            let meAsFriend = Friend(id: self.user!.id!, first: self.user!.userProfile.firstName, last: self.user!.userProfile.lastName, email: self.user!.userProfile.email)
        
            friendUser.friendList!.pendingReceivedApproval?.append(meAsFriend)

            // set friend user as a friend item, and add them to user's sent requests
//            let friend = Friend(id: friendUser.id!, first: friendUser.userProfile.firstName, last: friendUser.userProfile.lastName, email: friendUser.userProfile.email)
            if self.user!.friendList == nil { self.user!.friendList = FriendList() }
            self.user!.friendList!.pendingSentApproval?.append(friend)

            do {
                let myData = try FirebaseEncoder().encode(friendUser.friendList!.pendingReceivedApproval)
                let friendData = try FirebaseEncoder().encode(self.user!.friendList!.pendingSentApproval)

                // Write data to firebase
                ref.child(FirebaseStructure.Users).child(friendUser.id!).child(FirebaseStructure.CharmUser.Friends).child(FirebaseStructure.CharmUser.FriendList.PendingReceivedApproval).setValue(myData)

                ref.child(FirebaseStructure.Users).child(self.user!.id!).child(FirebaseStructure.CharmUser.Friends).child(FirebaseStructure.CharmUser.FriendList.PendingSentApproval).setValue(friendData)

                alert.title = "Sent Request"
                alert.message = "Your friend request has been sent.  Once the request has been approved by your friend, they will show up on your friends list."
                navVC.present(alert, animated: true, completion: nil)
            } catch let error {
                alert.title = "Request Failed"
                alert.message = "Your friend request failed.  Please try again later."
                print("~>Got an error: \(error)")
                navVC.present(alert, animated: true, completion: nil)
            }
        }
    }
    
}
