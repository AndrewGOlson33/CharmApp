//
//  ContactsViewModel.swift
//  Charm
//
//  Created by Daniel Pratt on 3/11/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit
import Firebase
import Contacts
import MessageUI

class ContactsViewModel: NSObject {
    
    enum ContactType {
        case Current
        case PendingReceived
        case PendingSent
        case ExistingNotInContacts
        case AddByPhone
    }
    
    static let shared = ContactsViewModel()
    
    let activityView = UIActivityIndicatorView(frame: .zero)
    
    // delegate for updating table view
    var delegate: TableViewRefreshDelegate? = nil
    
    var isLoading: Bool = false {
        didSet {
            delegate?.showActivity(isLoading)
        }
    }
    
    var hasLoaded: Bool = false
    
    // all users
    var allUsers: [CharmUser] = []
    
    // compute friends list properties
    var currentFriends: [Friend] {
        guard let thisUser = FirebaseModel.shared.charmUser, let friendsList = thisUser.friendList, let currentFriends = friendsList.currentFriends else { return [] }
        return currentFriends
    }
    
    var pendingReceived: [Friend] {
        guard let thisUser = FirebaseModel.shared.charmUser, let friendsList = thisUser.friendList, let pending = friendsList.pendingReceivedApproval else { return [] }
        return pending
    }
    
    var pendingSent: [Friend] {
        guard let thisUser = FirebaseModel.shared.charmUser, let friendsList = thisUser.friendList, let pending = friendsList.pendingSentApproval else { return [] }
        return pending
    }
    
    var sentText: [Friend] {
        guard let thisUser = FirebaseModel.shared.charmUser, let friendsList = thisUser.friendList, let sent = friendsList.sentText else { return [] }
        return sent
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
    
    // arrays used for search
    
    var filteredFriends: [Friend] = [] {
        didSet {
            filteredFriends.sort { (lhs, rhs) -> Bool in
                return lhs.lastName < rhs.lastName
            }
        }
    }
    
    var filteredPendingReceived: [Friend] = [] {
        didSet {
            filteredPendingReceived.sort { (lhs, rhs) -> Bool in
                return lhs.lastName < rhs.lastName
            }
        }
    }
    
    var filteredPendingSent: [Friend] = [] {
        didSet {
            filteredPendingSent.sort { (lhs, rhs) -> Bool in
                return lhs.lastName < rhs.lastName
            }
        }
    }
    
    var filteredExistingUsers: [Friend] = [] {
        didSet {
            filteredExistingUsers.sort { (lhs, rhs) -> Bool in
                return lhs.lastName < rhs.lastName
            }
        }
    }
    var filteredUsersToInvite: [Friend] = [] {
        didSet {
            filteredExistingUsers.sort { (lhs, rhs) -> Bool in
                return lhs.lastName < rhs.lastName
            }
        }
    }
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(updatedUser), name: FirebaseNotification.CharmUserDidUpdate, object: nil)
        
        guard let user = FirebaseModel.shared.charmUser else { return }
        if !UserDefaults.standard.bool(forKey: Defaults.hasMigrated) {
            user.friendList?.save()
            
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 30.0) { [weak self] in
                guard self != nil else { return }
                UserDefaults.standard.set(true, forKey: Defaults.hasMigrated)
            }
        }
    }
    
    private func loadUserList() {
        Database.database().reference().child(FirebaseStructure.usersLocation).observe(.value) { [weak self] (snapshot) in
            guard let self = self else { return }
            self.allUsers = []
            for child in snapshot.children {
                do {
                    guard let userSnap = child as? DataSnapshot else { continue }
                    if !self.allUsers.contains(where: { (user) -> Bool in
                        user.ref == userSnap.ref
                    }) { self.allUsers.append(try CharmUser(snapshot: userSnap)) }
                } catch let error {
                    print("~>There was an error trying to load a user from the child snapshot: \(error)")
                }
            }
            
            print("~>Loaded user list.")
            self.setupAddFriendsArrays()
        }
        
    }
    
    // MARK: - Data Access
    
    func configureCell(atIndex index: Int, withCell cell: ChatFriendListTableViewCell, filtered: Bool) -> ChatFriendListTableViewCell {
        
        let friend = filtered ? filteredFriends[index] : currentFriends[index]
        
        cell.lblName.text = "\(friend.firstName) \(friend.lastName)"
        
        // check to see if contacts has an image
        
        if let image = getPhoto(forFriend: friend) {
            cell.imgProfile.image = image
        } else {
            cell.imgProfile.image = UIImage(named: "icnTempProfile")
        }
        
        return cell
    }
    
    func configureCell(atIndex index: Int, withCell cell: FriendListTableViewCell, forType type: ContactType, filtered: Bool = false) -> FriendListTableViewCell {
        
        var friend: Friend! = nil
        
        // configure cell properties that vary by type
        switch type {
        case .Current:
            friend = filtered ? filteredFriends[index] : currentFriends[index]
            cell.lblDetail.text = "In friend list"
            cell.btnApprove.isHidden = true
        case .PendingReceived:
            friend = filtered ? filteredPendingReceived[index] : pendingReceived[index]
            cell.lblDetail.text = "Added you from: \(friend.email)"
            cell.btnApprove.setTitle("Approve", for: .normal)
            cell.btnApprove.isHidden = false
            cell.addMethod = .Approval
        case .PendingSent:
            friend = filtered ? filteredPendingSent[index] : pendingSent[index]
            cell.lblDetail.text = "Waiting for response."
            cell.btnApprove.isHidden = false
            cell.btnApprove.setTitle("Pending", for: .normal)
        case .ExistingNotInContacts:
            friend = filtered ? filteredExistingUsers[index] : existingUsers[index]
            cell.lblDetail.text = "In your contacts"
            cell.btnApprove.setTitle("+ Add", for: .normal)
            cell.btnApprove.isHidden = false
            cell.addMethod = .Email
        case .AddByPhone:
            friend = filtered ? filteredUsersToInvite[index] : usersToInvite[index]
            cell.lblDetail.text = friend.phone
            cell.btnApprove.setTitle("+ Add", for: .normal)
            cell.btnApprove.isHidden = false
            cell.addMethod = .Phone
        }
        
        // configure cell data
        cell.lblName.text = "\(friend.firstName) \(friend.lastName)"
        
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
        
        guard !isLoading else { return }
        isLoading = true
        
        // make sure user hasn't denied access
        let status = CNContactStore.authorizationStatus(for: .contacts)
        if status == .denied || status == .restricted {
            // present alert
            presentSettingsAlert()
        }
        
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { [weak self] (granted, error) in
            
            guard let self = self else { return }
            
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
                    if !self.contacts.contains(contact) { self.contacts.append(contact)
                    }
                    self.checkFriendList(for: contact)
                })
            } catch let error {
                print("~>Got an error: \(error)")
            }
            
            // load all users
            self.loadUserList()
        }
    }
    
    // Present an alert on top of the navigation controller
    
    fileprivate func presentSettingsAlert() {
        let settingsURL = URL(string: UIApplication.openSettingsURLString)!
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isLoading = false
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
        var phoneNumbers: [String] = []
        
        for email in contact.emailAddresses {
            emailAddresses.append(email.value as String)
        }
        
        for phone in contact.phoneNumbers {
            phoneNumbers.append(phone.value.stringValue.filter("0123456789".contains))
        }
        
        guard let contacts = FirebaseModel.shared.charmUser?.friendList?.currentFriends else {
            notInContacts.append(contact)
            return
        }
        
        if !contacts.enumerated().contains(where: { (index, friend) -> Bool in
            return emailAddresses.contains(friend.email) || (!friend.phone.isEmpty && phoneNumbers.contains(friend.phone))
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
    
    // MARK: - Search Filtering
    
    func filterSearch(forContacts: Bool, withText text: String) {
        let search = text.lowercased()
        switch forContacts {
        case true:
            // search for contact related arrays
            // find current friends who match search
            let current = currentFriends.filter { (friend) -> Bool in
                return friend.email.lowercased().contains(search) || "\(friend.firstName.lowercased()) \(friend.lastName.lowercased())".contains(search) || (!friend.phone.isEmpty && friend.phone.lowercased().contains(search))
            }
            
            // search received friend requests
            let received = pendingReceived.filter { (friend) -> Bool in
                return friend.email.lowercased().contains(search) || "\(friend.firstName.lowercased()) \(friend.lastName.lowercased())".contains(search) || (!friend.phone.isEmpty && friend.phone.lowercased().contains(search))
            }
            
            // search friend requests that have already been sent
            let sent = pendingSent.filter { (friend) -> Bool in
                return friend.email.lowercased().contains(search) || "\(friend.firstName.lowercased()) \(friend.lastName.lowercased())".contains(search) || (!friend.phone.isEmpty && friend.phone.lowercased().contains(search))
            }
            
            filteredFriends = current
            filteredPendingReceived = received
            filteredPendingSent = sent
        default:
            // search from friends you can add
            // start searching users who already exist in charm
            let existing = existingUsers.filter { (friend) -> Bool in
                return friend.email.lowercased().contains(search) || "\(friend.firstName.lowercased()) \(friend.lastName.lowercased())".contains(search) || (!friend.phone.isEmpty && friend.phone.lowercased().contains(search))
            }
            
            // next search users that could be invited
            let invite = usersToInvite.filter { (friend) -> Bool in
                return friend.email.lowercased().contains(search) || "\(friend.firstName.lowercased()) \(friend.lastName.lowercased())".contains(search) || (!friend.phone.isEmpty && friend.phone.lowercased().contains(search))
            }
            
            filteredExistingUsers = existing
            filteredUsersToInvite = invite
        }
        
        delegate?.updateTableView()
    }
    
    // setup the arrays for adding contacts
    fileprivate func setupAddFriendsArrays() {
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // only loop through contacts we know are not in the user's friend list
            for contact in self.notInContacts {
                var friendUser: CharmUser? = nil
                if self.allUsers.contains(where: { (user) -> Bool in
                    for email in contact.emailAddresses {
                        let email = email.value as String
                        if email.lowercased() == user.userProfile.email { friendUser = user; return true }
                    }
                    
                    for number in contact.phoneNumbers {
                        let phone = number.value.stringValue.filter("0123456789".contains)
                        if phone == user.userProfile.phone { friendUser = user; return true }
                    }
                    
                    return false
                }) {
                    guard let friendUser = friendUser, let id = friendUser.id else { continue }
                    let friend = Friend(id: id, first: friendUser.userProfile.firstName, last: friendUser.userProfile.lastName, email: friendUser.userProfile.email)
                    if !(friend.id == FirebaseModel.shared.charmUser.id) && !self.existingUsers.contains(where: { (existing) -> Bool in
                        return existing.email == friend.email
                    }) && !self.pendingReceived.contains(where: { (existing) -> Bool in
                        return existing.email == friend.email
                    }) && !self.pendingSent.contains(where: { (existing) -> Bool in
                        return existing.email == friend.email
                    }) {
                        self.existingUsers.append(friend)
                    }
                } else {
                    // get user data to create the contact with
                    let firstName = contact.givenName
                    let lastName = contact.familyName
                    var emailAddress = ""
                    if let emailItem = contact.emailAddresses.first {
                        emailAddress = emailItem.value as String
                    }
                    
                    var phone: String = ""
                    
                    for number in contact.phoneNumbers {
                        guard let label = number.label else { continue }
                        if label.lowercased().contains("iphone") || label.lowercased().contains("mobile") ||  label.lowercased().contains("main") {
                            phone = number.value.stringValue
                            break
                        }
                    }
                    
                    if phone.isEmpty { phone = contact.phoneNumbers.first?.value.stringValue ?? "" }
                    
                    guard !firstName.isEmpty && !phone.isEmpty && !self.currentFriends.contains(where: { (friend) -> Bool in
                        return friend.email == emailAddress || friend.phone == phone
                    }) else {
                        continue
                    }
                    
                    guard let key = Database.database().reference().childByAutoId().key else { continue }
                    let friend = Friend(id: key, first: firstName, last: lastName, email: emailAddress, phone: phone)
                    
                    if !self.usersToInvite.contains(where: { (existing) -> Bool in
                            return existing.email == friend.email && existing.phone == friend.phone && existing.firstName == existing.firstName && existing.lastName == friend.lastName
                        }) && !self.pendingReceived.contains(where: { (existing) -> Bool in
                            return existing.email == friend.email && existing.phone == friend.phone && existing.firstName == existing.firstName && existing.lastName == friend.lastName
                        }) && !self.pendingSent.contains(where: { (existing) -> Bool in
                            return existing.email == friend.email && existing.phone == friend.phone && existing.firstName == existing.firstName && existing.lastName == friend.lastName
                        }) && !self.sentText.contains(where: { (existing) -> Bool in
                            return existing.email == friend.email && existing.phone == friend.phone && existing.firstName == existing.firstName && existing.lastName == friend.lastName
                        })  { self.usersToInvite.append(friend) }
                }
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.isLoading = false
                self.checkForShowContactListNotification()
                self.delegate?.updateTableView()
                self.delegate?.showActivity(self.isLoading)
            }
            
            self.hasLoaded = true
            self.performFriendListMaintenence()
        }
    }
    
    // MARK: - Notifications
    
    private func checkForShowContactListNotification() {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else { return }
        if delegate.showContactListFromNotification {
            delegate.showContactListFromNotification = false
            NotificationCenter.default.post(name: FirebaseNotification.showContactListFromNotification, object: nil)
        }
    }
    
    // updates should be live
    @objc private func updatedUser(_ sender: Notification) {
        guard let updatedUser = sender.object as? CharmUser else { return }
        FirebaseModel.shared.charmUser = updatedUser
        
        // load contact list
        guard !isLoading, !hasLoaded else { return }
        loadContacts()
    }
}

// MARK: - Delegate Function to handle approving a friend request

extension ContactsViewModel: FriendManagementDelegate {
    
    func delete(friend: Friend, fromTableView tableView: UITableView, atIndexPath indexPath: IndexPath, ofType type: ContactType) {
        
        guard let user = FirebaseModel.shared.charmUser, let myId = user.id else { return }
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            self.isLoading = true
            var removeCharmUser: Friend? = nil
            for user in self.allUsers {
                if user.id != friend.id { continue }
                if let fl = user.friendList {
                    if let cf = fl.currentFriends, cf.contains(where: { (friend) -> Bool in
                        if friend.id == myId { removeCharmUser = friend; return true }
                        return false
                    }) { break }
                    else if let ps = fl.pendingSentApproval, ps.contains(where: { (friend) -> Bool in
                        if friend.id == myId { removeCharmUser = friend; return true }
                        return false
                    }) { break }
                    else if let pr = fl.pendingReceivedApproval, pr.contains(where: { (friend) -> Bool in
                        if friend.id == myId { removeCharmUser = friend; return true }
                        return false
                    }) { break }
                }
            }
            
            friend.ref?.removeValue()
            if let charmUser = removeCharmUser { charmUser.ref?.removeValue() }
        }
    }
    
    func approveFriendRequest(withId id: String) {
        // first move friend from received to current friends
        guard let user = FirebaseModel.shared.charmUser, let myID = user.id, allUsers.count > 0 else {
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
                self.approveFriendRequest(withId: id)
                return
            }
            return
        }
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            
            guard let friendUser: CharmUser = self.allUsers.first(where: { (charmUser) -> Bool in
                charmUser.id == id
            }) else { return }
            
            // grab both friend lists
            guard var friendList = user.friendList, let received = friendList.pendingReceivedApproval else { return }
            if friendList.currentFriends == nil { friendList.currentFriends = [] }
            
            guard var friendFriendList = friendUser.friendList, let sent = friendFriendList.pendingSentApproval else { return }
            if friendFriendList.currentFriends == nil { friendFriendList.currentFriends =  [] }
            
            // remove from current locations on respective friend lists
            guard var user = sent.first(where: { (friend) -> Bool in
                friend.id == myID
            }) else { return }
            
            guard var friend = received.first(where: { (friend) -> Bool in
                friend.id == id
            }) else { return }
            
            self.isLoading = true
            
            // remove from location
            user.ref?.removeValue()
            friend.ref?.removeValue()
            
            // setup new ref
            
            let usersRoot = Database.database().reference().child(FirebaseStructure.usersLocation)
            let newUserRef = usersRoot.child(id).child(FirebaseStructure.CharmUser.friendListLocation).child(FirebaseStructure.CharmUser.FriendList.currentFriends).child(myID)
            let newFriendRef = usersRoot.child(myID).child(FirebaseStructure.CharmUser.friendListLocation).child(FirebaseStructure.CharmUser.FriendList.currentFriends).child(id)
            
            user.ref = newUserRef
            friend.ref = newFriendRef
            
            user.save()
            friend.save()
        }
    }
    
    // MARK: - Private Helper Function to Perform Maintenence
    
    func performFriendListMaintenence() {
        guard let user = FirebaseModel.shared.charmUser else {
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self else { return }
                self.performFriendListMaintenence()
                return
            }
            return
        }
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            guard var friendList = user.friendList else { return }
            
            var changesToSelf = false
                   
            for currentFriend in friendList.currentFriends ?? [] {
                if friendList.pendingReceivedApproval?.contains(where: { (received) -> Bool in
                       return received.id == currentFriend.id
                   }) ?? false {
                       changesToSelf = true
                       friendList.pendingReceivedApproval?.removeAll(where: { (received) -> Bool in
                           return received.id == currentFriend.id
                       })
                   }
                   
                   if friendList.pendingSentApproval?.contains(where: { (sent) -> Bool in
                       return sent.id == currentFriend.id
                   }) ?? false {
                       changesToSelf = true
                       friendList.pendingSentApproval?.removeAll(where: { (sent) -> Bool in
                           return sent.id == currentFriend.id
                       })
                   }
                   
                guard let id = currentFriend.id else { continue }
                self.checkFriendList(for: id, atLocation: .Current)
            }
               
               for receivedFriend in friendList.pendingReceivedApproval ?? [] {
        
                   if friendList.pendingSentApproval?.contains(where: { (sent) -> Bool in
                       return sent.id == receivedFriend.id
                   }) ?? false {
                       changesToSelf = true
                       friendList.pendingSentApproval?.removeAll(where: { (sent) -> Bool in
                           return sent.id == receivedFriend.id
                       })
                   }
                   
                   guard let id = receivedFriend.id else { continue }
                self.checkFriendList(for: id, atLocation: .PendingReceived)
               }
               
               for sentFriend in friendList.pendingSentApproval ?? [] {
                   // all lists have been cleared at this point so just check the friend list
                   guard let id = sentFriend.id else { continue }
                self.checkFriendList(for: id, atLocation: .PendingSent)
               }
               
               if changesToSelf {
                   friendList.save()
               }
               
               // Do it all over again every thirty minutes in the background
               
               DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1800) {
                   self.performFriendListMaintenence()
            }
        }
    }
    
    private func checkFriendList(for id: String, atLocation location: ContactType) {
        let ref = Database.database().reference().child(FirebaseStructure.usersLocation).child(id).child(FirebaseStructure.CharmUser.friendListLocation)
        
        DispatchQueue.global(qos: .utility).async {
            ref.observeSingleEvent(of: .value) { (snapshot) in
                if !snapshot.exists() { return }

                do {
                    var list = try FriendList(snapshot: snapshot)
                    let meAsFriend = Friend(id: FirebaseModel.shared.charmUser.id!, first: FirebaseModel.shared.charmUser.userProfile.firstName, last: FirebaseModel.shared.charmUser.userProfile.lastName, email: FirebaseModel.shared.charmUser.userProfile.email)
                    
                    switch location {
                    case .Current:
                        var listHasChanges: Bool = false
                        if var current = list.currentFriends, !current.contains(where: { (friend) -> Bool in
                            return friend.id == FirebaseModel.shared.charmUser.id
                        }) {
                            current.append(meAsFriend)
                            list.currentFriends = current
                            listHasChanges = true
                        } else if list.currentFriends == nil {
                            list.currentFriends = [meAsFriend]
                            listHasChanges = true
                        }
                        
                        if listHasChanges {
                            list.pendingSentApproval?.removeAll(where: { (friend) -> Bool in
                                friend.id == FirebaseModel.shared.charmUser.id
                            })
                            
                            list.pendingReceivedApproval?.removeAll(where: { (friend) -> Bool in
                                friend.id == FirebaseModel.shared.charmUser.id
                            })
                            
                            list.save()
                        }
                        
                    case .PendingReceived:
                        var listHasChanges: Bool = false
                        if var sent = list.pendingSentApproval, !sent.contains(where: { (friend) -> Bool in
                            return friend.id == FirebaseModel.shared.charmUser.id
                        }) {
                            sent.append(meAsFriend)
                            list.pendingSentApproval = sent
                            listHasChanges = true
                        } else if list.pendingSentApproval == nil {
                            list.pendingSentApproval = [meAsFriend]
                            listHasChanges = true
                        }
                        
                        if listHasChanges {
                            list.currentFriends?.removeAll(where: { (friend) -> Bool in
                                friend.id == FirebaseModel.shared.charmUser.id
                            })
                            
                            list.pendingReceivedApproval?.removeAll(where: { (friend) -> Bool in
                                friend.id == FirebaseModel.shared.charmUser.id
                            })
                            
                            list.save()
                        }
                        
                    case .PendingSent:
                        var listHasChanges: Bool = false
                        if var received = list.pendingReceivedApproval, !received.contains(where: { (friend) -> Bool in
                            return friend.id == FirebaseModel.shared.charmUser.id
                        }) {
                            received.append(meAsFriend)
                            list.pendingReceivedApproval = received
                            listHasChanges = true
                        } else if list.pendingReceivedApproval == nil {
                            list.pendingReceivedApproval = [meAsFriend]
                            listHasChanges = true
                        }
                        
                        if listHasChanges {
                            list.currentFriends?.removeAll(where: { (friend) -> Bool in
                                friend.id == FirebaseModel.shared.charmUser.id
                            })
                            
                            list.pendingSentApproval?.removeAll(where: { (friend) -> Bool in
                                friend.id == FirebaseModel.shared.charmUser.id
                            })
                            
                            list.save()
                        }
                    default:
                        print("~>Default")
                        return
                    }
                    
                } catch let error {
                    print("~>Got an error trying to decode values: \(error)")
                }
            }
        }
    }
    
    // MARK: - Private Helper Functions that do the heavy lifting for friend adding
    
    func sendEmailRequest(toFriend friend: Friend) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self, let user = FirebaseModel.shared.charmUser, let friendId = friend.id, let myId = user.id else { return }
            guard var meAsFriend = FirebaseModel.shared.meAsFriend else { return }
            var friend = friend
            // get the friend user
            guard var friendUser = self.allUsers.first(where: { (user) -> Bool in
                user.id == friendId
            }) else {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.showAlert(title: "Error", message: "An error occurred while trying to add the user.  Please force close the app, and try again.")
                }
                return
            }
            
            if friendUser.friendList == nil { friendUser.friendList = FriendList() }
            else if let myList = user.friendList, let received = myList.pendingReceivedApproval, received.contains(where: { (friend) -> Bool in
                friend.id == friendUser.id
            }) {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.showAlert(title: "Pending Request", message: "This user has already sent you a friend request.  Please accept their request to add as a friend.")
                }
                return
            }
            
            let usersRef = Database.database().reference().child(FirebaseStructure.usersLocation)
            let meAsFriendRef = usersRef.child(friendId).child(FirebaseStructure.CharmUser.friendListLocation).child(FirebaseStructure.CharmUser.FriendList.pendingReceivedApproval).child(myId)
            let friendRef = usersRef.child(myId).child(FirebaseStructure.CharmUser.friendListLocation).child(FirebaseStructure.CharmUser.FriendList.pendingSentApproval).child(friendId)
            
            friend.ref = friendRef
            meAsFriend.ref = meAsFriendRef
            
            friend.save()
            meAsFriend.save()
            
            self.resetFriendLists()
        }
    }
    
    func resetFriendLists() {
        contacts.removeAll()
        notInContacts.removeAll()
        existingUsers.removeAll()
        usersToInvite.removeAll()
        
        isLoading = false
        loadContacts()
    }
    
    func sendTextRequest(toFriend friend: Friend) {
        
        // setup deep link
        guard let id = FirebaseModel.shared.charmUser.id, let url = URL(string: "https://blaumagier.com/friendinvite?id=\(id)") else { return }
        guard let deepComponents = DynamicLinkComponents(link: url, domainURIPrefix: FirebaseStructure.DeepLinks.prefixURL) else {
            print("~>Unable to create deep components.")
            return }
        
        let me = FirebaseModel.shared.charmUser.userProfile
        // start activity
        
        let window = UIApplication.shared.keyWindow!
        let viewActivity = UIActivityIndicatorView(style: .whiteLarge)
        viewActivity.center = window.center
        viewActivity.color = #colorLiteral(red: 0.1323429346, green: 0.1735357642, blue: 0.2699699998, alpha: 1)
        viewActivity.hidesWhenStopped = true
        
        window.addSubview(viewActivity)
        window.bringSubviewToFront(viewActivity)
        
        viewActivity.startAnimating()
        
        let iOSParams = DynamicLinkIOSParameters(bundleID: FirebaseStructure.DeepLinks.bundleID)
        iOSParams.minimumAppVersion = FirebaseStructure.DeepLinks.minAppVersion
        iOSParams.appStoreID = FirebaseStructure.DeepLinks.appStoreID
        deepComponents.iOSParameters = iOSParams
        
        // setup social media meta tags
        let metaTags = DynamicLinkSocialMetaTagParameters()
        metaTags.title = "Become Friends With: \(me.firstName) on Charm"
        metaTags.descriptionText = "Just launch the app after it has downloaded and \(me.firstName) will be added automatically."
        metaTags.imageURL = URL(string: "https://firebasestorage.googleapis.com/v0/b/charismaanalytics-57703.appspot.com/o/share%2Fimg_share.png?alt=media&token=49b75795-27b5-4638-88fd-02ea36ab9689")
        deepComponents.socialMetaTagParameters = metaTags
        
        // build a short dynamic link
        let options = DynamicLinkComponentsOptions()
        options.pathLength = .unguessable
        deepComponents.options = options
        
        deepComponents.shorten { (shorturl, warnings, error) in
            
            if let error = error {
                print(error.localizedDescription)
                print(error)
                viewActivity.stopAnimating()
                return
            }
            
            guard let shortLink = shorturl else {
                print("Unable to get short link url, even though there was no error")
                viewActivity.stopAnimating()
                return
            }
            
            let navVC = (UIApplication.shared.delegate as! AppDelegate).window!.rootViewController as! UINavigationController
            let alert = UIAlertController(title: "", message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            
            guard MFMessageComposeViewController.canSendText() else {
                alert.title = "Error Adding Friend"
                alert.message = "This device is not setup for sending text messages."
                navVC.present(alert, animated: true, completion: nil)
                viewActivity.stopAnimating()
                return
            }
            
            let phone = friend.phone
            
            // setup message
            let composeVC = MFMessageComposeViewController()
            composeVC.messageComposeDelegate = self
            
            // Configure the fields of the interface.
            composeVC.recipients = [phone]
            var userName = ""
            if let user = FirebaseModel.shared.charmUser, let uid = user.id {
                userName = " \(user.userProfile.firstName)"
                if var friendList = user.friendList, let _ = friendList.sentText {
                    friendList.sentText!.append(friend)
                    self.updateSentText(with: friendList, forUid: uid)
                } else if var friendList = user.friendList {
                    friendList.sentText = [friend]
                    self.updateSentText(with: friendList, forUid: uid)
                } else {
                    let friendList = FriendList(currentFriends: [], pendingSentApproval: [], pendingReceivedApproval: [], sentText: [friend])
                    self.updateSentText(with: friendList, forUid: uid)
                }
            }
            
            composeVC.body = "Hey \(friend.firstName), your friend \(userName) has invited you Charm. Charm is an app \(userName) is using to have better conversations.  Download using the link below.\n\n\(shortLink)"
        
            
            // Present the view controller modally.
            navVC.present(composeVC, animated: true, completion: {
                viewActivity.stopAnimating()
            })
        }
    }
    
    fileprivate func updateSentText(with friendList: FriendList, forUid uid: String) {
        DispatchQueue.global(qos: .utility).async {
            friendList.save()
        }
    }
    
    fileprivate func showAlert(title: String, message: String) {
        DispatchQueue.main.async { [weak self] in
            guard self != nil else { return }
            
            // setup views for displaying error alerts
            let navVC = (UIApplication.shared.delegate as! AppDelegate).window!.rootViewController as! UINavigationController
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            navVC.present(alert, animated: true, completion: nil)
        }
    }
}

extension ContactsViewModel: MFMessageComposeViewControllerDelegate {
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        
        // Dismiss the message compose view controller.
        DispatchQueue.main.async {
            controller.dismiss(animated: true, completion: nil)
        }
    }
}
