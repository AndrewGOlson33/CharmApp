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

class ContactsViewModel: NSObject {
    
    enum ContactType {
        case Current
        case PendingReceived
        case PendingSent
        case ExistingNotInContacts
        case AddByPhone
    }
    
    static let shared = ContactsViewModel()
    
    // delegate for updating table view
    var delegate: TableViewRefreshDelegate? = nil
    
    // user object
    var user = CharmUser.shared
    
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
    
    var sentText: [Friend] {
        guard let thisUser = user, let friendsList = thisUser.friendList, let sent = friendsList.sentText else { return [] }
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
        
        // load contact list
        loadContacts()
        setupAddFriendsArrays()
        
        // refresh table view
        delegate?.updateTableView()
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
                    if !self.contacts.contains(contact) { self.contacts.append(contact) }
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
        var phoneNumbers: [String] = []
        
        for email in contact.emailAddresses {
            emailAddresses.append(email.value as String)
        }
        
        for phone in contact.phoneNumbers {
            phoneNumbers.append(phone.value.stringValue.filter("0123456789".contains))
        }
        
        guard let contacts = user?.friendList?.currentFriends else {
            notInContacts.append(contact)
            return
        }
        if !contacts.enumerated().contains(where: { (index, friend) -> Bool in
            return emailAddresses.contains(friend.email) || phoneNumbers.contains(friend.phone ?? "")
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
                return friend.email.lowercased().contains(search) || "\(friend.firstName.lowercased()) \(friend.lastName.lowercased())".contains(search) || friend.phone?.lowercased().contains(search) ?? false
            }
            
            // search received friend requests
            let received = pendingReceived.filter { (friend) -> Bool in
                return friend.email.lowercased().contains(search) || "\(friend.firstName.lowercased()) \(friend.lastName.lowercased())".contains(search) || friend.phone?.lowercased().contains(search) ?? false
            }
            
            // search friend requests that have already been sent
            let sent = pendingSent.filter { (friend) -> Bool in
                return friend.email.lowercased().contains(search) || "\(friend.firstName.lowercased()) \(friend.lastName.lowercased())".contains(search) || friend.phone?.lowercased().contains(search) ?? false
            }
            
            filteredFriends = current
            filteredPendingReceived = received
            filteredPendingSent = sent
        default:
            // search from friends you can add
            // start searching users who already exist in charm
            let existing = existingUsers.filter { (friend) -> Bool in
                return friend.email.lowercased().contains(search) || "\(friend.firstName.lowercased()) \(friend.lastName.lowercased())".contains(search) || friend.phone?.lowercased().contains(search) ?? false
            }
            
            // next search users that could be invited
            let invite = usersToInvite.filter { (friend) -> Bool in
                return friend.email.lowercased().contains(search) || "\(friend.firstName.lowercased()) \(friend.lastName.lowercased())".contains(search) || friend.phone?.lowercased().contains(search) ?? false
            }
            
            filteredExistingUsers = existing
            filteredUsersToInvite = invite
        }
        
        delegate?.updateTableView()
    }
    
    // setup the arrays for adding contacts
    fileprivate func setupAddFriendsArrays() {
        let ref = Database.database().reference().child(FirebaseStructure.Users)
        
        DispatchQueue.global(qos: .utility).async {
            let contactsGroup = DispatchGroup()
            
            // only loop through contacts we know are not in the user's friend list
            for contact in self.notInContacts {
                var found: Bool = false
                contactsGroup.enter()
                let contactGroup = DispatchGroup()
                
                for email in contact.emailAddresses {
                    contactGroup.enter()
                    let value = email.value as String
                    let emailQuery = ref.queryOrdered(byChild: "userProfile/email").queryEqual(toValue: value).queryLimited(toFirst: 1)
                    emailQuery.observeSingleEvent(of: .value) { (snapshot) in
                        if !snapshot.exists() {
                            contactGroup.leave()
                            return
                        }
                        
                        if let results = snapshot.value as? [AnyHashable:Any], let first = results.first?.value {
                            found = true
                            let friendUser = try! FirebaseDecoder().decode(CharmUser.self, from: first)
                            let friend = Friend(id: friendUser.id!, first: friendUser.userProfile.firstName, last: friendUser.userProfile.lastName, email: friendUser.userProfile.email)
                            if !(friend.id == self.user?.id) && !self.existingUsers.contains(where: { (existing) -> Bool in
                                return existing.email == friend.email
                            }) && !self.pendingReceived.contains(where: { (existing) -> Bool in
                                return existing.email == friend.email
                            }) && !self.pendingSent.contains(where: { (existing) -> Bool in
                                return existing.email == friend.email
                            }) {
                                self.existingUsers.append(friend)
                            }
                            
                            contactGroup.leave()
                        }
                    }
                }
                
                for number in contact.phoneNumbers {
                    contactGroup.enter()
                    let phone = number.value.stringValue.filter("0123456789".contains)
                    let phoneQuery = ref.queryOrdered(byChild: "userProfile/phone").queryEqual(toValue: phone).queryLimited(toFirst: 1)
                    phoneQuery.observeSingleEvent(of: .value) { (snapshot) in
                        if !snapshot.exists() {
                            contactGroup.leave()
                            return
                        }
                        
                        if let results = snapshot.value as? [AnyHashable:Any], let first = results.first?.value {
                            do {
                                let friendUser = try FirebaseDecoder().decode(CharmUser.self, from: first)
                                let friend = Friend(id: friendUser.id!, first: friendUser.userProfile.firstName, last: friendUser.userProfile.lastName, email: friendUser.userProfile.email)
                                print("~>Existing phone number in contacts: \(friend.firstName) \(friend.lastName) \(friend.email)")
                                if !(friend.id == self.user?.id) && !self.existingUsers.contains(where: { (existing) -> Bool in
                                    return existing.email == friend.email
                                }) && !self.pendingReceived.contains(where: { (existing) -> Bool in
                                    return existing.email == friend.email
                                }) && !self.pendingSent.contains(where: { (existing) -> Bool in
                                    return existing.email == friend.email
                                }) {
                                    self.existingUsers.append(friend)
                                }
                                contactGroup.leave()
                            } catch let error {
                                print("~>There was an error: \(error)")
                                contactGroup.leave()
                            }
                            
                        }
                    }
                }
                
                contactGroup.notify(queue: .main) {
                    if !found {
                        let firstName = contact.givenName
                        let lastName = contact.familyName
                        var emailAddress = ""
                        if let emailItem = contact.emailAddresses.first {
                            emailAddress = emailItem.value as String
                        }
                        
                        
                        var phone: String = ""
                        var found: Bool = false
                        
                        for number in contact.phoneNumbers {
                            guard let label = number.label else { continue }
                            if label.lowercased().contains("iphone") || label.lowercased().contains("mobile") || label.lowercased().contains("iphone") || label.lowercased().contains("main") {
                                phone = number.value.stringValue
                                found = true
                                break
                            }
                        }
                        
                        if !found {
                            phone = contact.phoneNumbers.first?.value.stringValue ?? ""
                        }
                        
                        
                        guard !firstName.isEmpty && !phone.isEmpty && !self.currentFriends.contains(where: { (friend) -> Bool in
                            return friend.email == emailAddress || friend.phone == phone
                        }) else {
                            contactsGroup.leave()
                            return
                        }
                        var friend = Friend(id: "N/A", first: firstName, last: lastName, email: emailAddress)
                        friend.phone = phone
                        if !self.usersToInvite.contains(where: { (existing) -> Bool in
                            return existing.email == friend.email && existing.phone == friend.phone && existing.firstName == existing.firstName && existing.lastName == friend.lastName
                        }) && !self.pendingReceived.contains(where: { (existing) -> Bool in
                            return existing.email == friend.email && existing.phone == friend.phone && existing.firstName == existing.firstName && existing.lastName == friend.lastName
                        }) && !self.pendingSent.contains(where: { (existing) -> Bool in
                            return existing.email == friend.email && existing.phone == friend.phone && existing.firstName == existing.firstName && existing.lastName == friend.lastName
                        }) && !self.sentText.contains(where: { (existing) -> Bool in
                            return existing.email == friend.email && existing.phone == friend.phone && existing.firstName == existing.firstName && existing.lastName == friend.lastName
                        })  { self.usersToInvite.append(friend) }
                        contactsGroup.leave()
                        self.delegate?.updateTableView()
                    } else {
                        contactsGroup.leave()
                        self.delegate?.updateTableView()
                    }
                }
                
                
            }
            
            contactsGroup.notify(queue: .main) {
                self.delegate?.updateTableView()
                self.performFriendListMaintenence()
            }
        }
        
        
    }
    
    // MARK: - Notifications
    
    // updates should be live
    @objc private func updatedUser(_ sender: Notification) {
        guard let updatedUser = sender.object as? CharmUser else { return }
        user = updatedUser
        
        // load contact list
        loadContacts()
        setupAddFriendsArrays()
        
        // refresh table view
        delegate?.updateTableView()
    }
}

// MARK: - Delegate Function to handle approving a friend request

extension ContactsViewModel: FriendManagementDelegate {
    
    func delete(friend: Friend, fromTableView tableView: UITableView, atIndexPath indexPath: IndexPath, ofType type: ContactType) {
        // Make sure this is all done on the main thread
        
        DispatchQueue.main.async {
            guard let user = self.user, let myId = user.id, let id = friend.id else { return }
            
            var myTypeLocation: String = ""
            var friendTypeLocation: String = ""
            var myNewFriends: [Friend]!
            tableView.beginUpdates()
            switch type {
            case .Current:
                myTypeLocation = FirebaseStructure.CharmUser.FriendList.CurrentFriends
                friendTypeLocation = FirebaseStructure.CharmUser.FriendList.CurrentFriends
                self.user!.friendList!.currentFriends!.remove(at: indexPath.row)
                myNewFriends = self.user!.friendList!.currentFriends!
            case .PendingReceived:
                myTypeLocation = FirebaseStructure.CharmUser.FriendList.PendingReceivedApproval
                friendTypeLocation = FirebaseStructure.CharmUser.FriendList.PendingSentApproval
                self.user!.friendList!.pendingReceivedApproval!.remove(at: indexPath.row)
                myNewFriends = self.user!.friendList!.pendingReceivedApproval!
            case .PendingSent:
                myTypeLocation = FirebaseStructure.CharmUser.FriendList.PendingSentApproval
                friendTypeLocation = FirebaseStructure.CharmUser.FriendList.PendingReceivedApproval
                self.user!.friendList!.pendingSentApproval!.remove(at: indexPath.row)
                myNewFriends = self.user!.friendList!.pendingSentApproval!
            default:
                tableView.endUpdates()
                return
            }
            
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
            
            let myRef = Database.database().reference().child(FirebaseStructure.Users).child(myId).child(FirebaseStructure.CharmUser.Friends).child(myTypeLocation)
            let friendRef = Database.database().reference().child(FirebaseStructure.Users).child(id).child(FirebaseStructure.CharmUser.Friends).child(friendTypeLocation)
            
            DispatchQueue.global(qos: .utility).async {
                friendRef.observeSingleEvent(of: .value, with: { (snapshot) in
                    guard let values = snapshot.value as? NSArray else { return }
                    var friendsFriendlist: [Friend] = []
                    do {
                        // first get friendlist for friend
                        for friend in values {
                            friendsFriendlist.append(try FirebaseDecoder().decode(Friend.self, from: friend))
                        }
                        
                        guard let index = friendsFriendlist.firstIndex(where: { (friend) -> Bool in
                            friend.id == myId
                        }) else {
                            print("~>Not in friend's list, just deleting from mine.")
                            let myFriendData = try FirebaseEncoder().encode(myNewFriends)
                            myRef.setValue(myFriendData)
                            return
                        }
                        
                        friendsFriendlist.remove(at: index)
                        
                        // now encode and save data
                        let myFriendData = try FirebaseEncoder().encode(myNewFriends)
                        let friendsData = try FirebaseEncoder().encode(friendsFriendlist)
                        
                        myRef.setValue(myFriendData) {
                            (error:Error?, ref:DatabaseReference) in
                            if let error = error {
                                print("~>Data could not be saved: \(error).")
                            } else {
                                print("~>Data saved successfully!")
                            }
                        }
                        friendRef.setValue(friendsData)
                    } catch let error {
                        print("~>There was an error converting friend lists to delete: \(error)")
                    }
                })
            }
        }
        
    }
    
    func approveFriendRequest(withId id: String) {
        // first move friend from received to current friends
        guard var user = user, let myID = user.id else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.approveFriendRequest(withId: id)
                return
            }
            return
        }
        
        // set base reference
        let ref = Database.database().reference()

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
        
        if user.friendList!.pendingReceivedApproval?.count == 0 { user.friendList!.pendingReceivedApproval = nil }
        
        // write data to firebase
        
        DispatchQueue.global(qos: .utility).async {
            do {
                let friendList = try FirebaseEncoder().encode(user.friendList!)
                print("~>Setting uid: \(user.id!) friendlist: \(friendList)")
                ref.child(FirebaseStructure.Users).child(user.id!).child(FirebaseStructure.CharmUser.Friends).setValue(friendList) {
                    (error:Error?, ref:DatabaseReference) in
                    if let error = error {
                        print("~>Data could not be saved: \(error).")
                    } else {
                        print("~>Data saved successfully!")
                    }
                }
                
            } catch let error {
                print("~>Got an error: \(error)")
                return
            }
            
            // finally move user from sent to current friends on friend's friend list
            
            ref.child(FirebaseStructure.Users).child(id).observeSingleEvent(of: .value) { (snapshot) in
                guard let value = snapshot.value else {
                    print("~>Unable to get snapshot value for friend.")
                    return
                }
                
                print("~>Got friend's snapshot, now going to update friend list.")
                // get the user object
                var friendUser = try! FirebaseDecoder().decode(CharmUser.self, from: value)
                if friendUser.friendList == nil { friendUser.friendList = FriendList() }
                let pending = friendUser.friendList?.pendingSentApproval
                if friendUser.friendList?.currentFriends == nil { friendUser.friendList?.currentFriends = [] }
                
                if pending == nil {
                    print("~>Returning because of nil pending.")
                    return
                }
                
                var meFriend: Friend!
                for (index, user) in pending!.enumerated() {
                    if user.id == myID {
                        meFriend = user
                        friendUser.friendList!.pendingSentApproval!.remove(at: index)
                        friendUser.friendList?.currentFriends?.append(meFriend)
                        print("~>Removed item from friend's friend list.")
                        break
                    }
                }
                
                if friendUser.friendList!.pendingSentApproval?.count == 0 { friendUser.friendList!.pendingSentApproval = nil }
                
                // write changes to firebase
                do {
                    let friendsFriendList = try FirebaseEncoder().encode(friendUser.friendList!)
                    print("~>Going to set friend user's friends list: \(friendsFriendList)")
                    ref.child(FirebaseStructure.Users).child(id).child(FirebaseStructure.CharmUser.Friends).setValue(friendsFriendList) {
                        (error:Error?, ref:DatabaseReference) in
                        if let error = error {
                            print("~>Data could not be saved: \(error).")
                        } else {
                            print("~>Data saved successfully!")
                        }
                    }
                    
                } catch let error {
                    print("~>Got an error: \(error)")
                }
            }
        }
        
        
    }
    
    // MARK: - Private Helper Function to Perform Maintenence
    
    func performFriendListMaintenence() {
        guard let user = user else {
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 1.0) {
                self.performFriendListMaintenence()
                return
            }
            return
        }
        
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
            checkFriendList(for: id, atLocation: .Current)
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
            checkFriendList(for: id, atLocation: .PendingReceived)
        }
        
        for sentFriend in friendList.pendingSentApproval ?? [] {
            // all lists have been cleared at this point so just check the friend list
            guard let id = sentFriend.id else { continue }
            checkFriendList(for: id, atLocation: .PendingSent)
        }
        
        if changesToSelf {
            do {
                let list = try FirebaseEncoder().encode(friendList)
                Database.database().reference().child(FirebaseStructure.Users).child(user.id!).child(FirebaseStructure.CharmUser.Friends).setValue(list) {
                    (error:Error?, ref:DatabaseReference) in
                    if let error = error {
                        print("~>Data could not be saved: \(error).")
                    } else {
                        print("~>Data saved successfully!")
                    }
                }
            } catch let error {
                print("~>Got an error encoding friend list after maintenence changes: \(error)")
            }
        }
        
        // Do it all over again very thirty minutes in the background
        
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 1800) {
            self.performFriendListMaintenence()
        }
        
    }
    
    private func checkFriendList(for id: String, atLocation location: ContactType) {
        let ref = Database.database().reference().child(FirebaseStructure.Users).child(id).child(FirebaseStructure.CharmUser.Friends)
        
        DispatchQueue.global(qos: .utility).async {
            ref.observeSingleEvent(of: .value) { (snapshot) in
                if !snapshot.exists() { return }
                
                guard let value = snapshot.value else { return }
                do {
                    var list = try FirebaseDecoder().decode(FriendList.self, from: value)
                    let meAsFriend = Friend(id: self.user!.id!, first: self.user!.userProfile.firstName, last: self.user!.userProfile.lastName, email: self.user!.userProfile.email)
                    
                    switch location {
                    case .Current:
                        var listHasChanges: Bool = false
                        if var current = list.currentFriends, !current.contains(where: { (friend) -> Bool in
                            return friend.id == self.user?.id
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
                                friend.id == self.user?.id
                            })
                            
                            list.pendingReceivedApproval?.removeAll(where: { (friend) -> Bool in
                                friend.id == self.user?.id
                            })
                            
                            let data = try FirebaseEncoder().encode(list)
                            
                            ref.setValue(data) {
                                (error:Error?, ref:DatabaseReference) in
                                if let error = error {
                                    print("~>Data could not be saved: \(error).")
                                } else {
                                    print("~>Data saved successfully!")
                                }
                            }
                        }
                        
                    case .PendingReceived:
                        var listHasChanges: Bool = false
                        if var sent = list.pendingSentApproval, !sent.contains(where: { (friend) -> Bool in
                            return friend.id == self.user?.id
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
                                friend.id == self.user?.id
                            })
                            
                            list.pendingReceivedApproval?.removeAll(where: { (friend) -> Bool in
                                friend.id == self.user?.id
                            })
                            
                            let data = try FirebaseEncoder().encode(list)
                            
                            ref.setValue(data) {
                                (error:Error?, ref:DatabaseReference) in
                                if let error = error {
                                    print("~>Data could not be saved: \(error).")
                                } else {
                                    print("~>Data saved successfully!")
                                }
                            }
                        }
                        
                    case .PendingSent:
                        var listHasChanges: Bool = false
                        if var received = list.pendingReceivedApproval, !received.contains(where: { (friend) -> Bool in
                            return friend.id == self.user?.id
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
                                friend.id == self.user?.id
                            })
                            
                            list.pendingSentApproval?.removeAll(where: { (friend) -> Bool in
                                friend.id == self.user?.id
                            })
                            
                            let data = try FirebaseEncoder().encode(list)
                            
                            ref.setValue(data) {
                                (error:Error?, ref:DatabaseReference) in
                                if let error = error {
                                    print("~>Data could not be saved: \(error).")
                                } else {
                                    print("~>Data saved successfully!")
                                }
                            }
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
        // setup views for displaying error alerts
        let navVC = (UIApplication.shared.delegate as! AppDelegate).window!.rootViewController as! UINavigationController
        let alert = UIAlertController(title: "", message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))

        let ref = Database.database().reference()
        let emailQuery = ref.child(FirebaseStructure.Users).queryOrdered(byChild: "userProfile/email").queryEqual(toValue: friend.email).queryLimited(toFirst: 1)
        
        DispatchQueue.global(qos: .utility).async {
            emailQuery.observeSingleEvent(of: .value) { (snapshot) in
                guard let results = snapshot.value as? [AnyHashable:Any], let first = results.first?.value else {
                    alert.title = "Unable to Send Request"
                    alert.message = "The request not able to be sent at this time.  Please try again later."
                    DispatchQueue.main.async {
                        navVC.present(alert, animated: true, completion: nil)
                    }
                    
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
                            DispatchQueue.main.async {
                                navVC.present(alert, animated: true, completion: nil)
                            }
                            
                            return
                        }
                    }
                }
                
                let meAsFriend = Friend(id: self.user!.id!, first: self.user!.userProfile.firstName, last: self.user!.userProfile.lastName, email: self.user!.userProfile.email)
                
                
                if friendUser.friendList!.pendingReceivedApproval == nil { friendUser.friendList!.pendingReceivedApproval = [] }
                friendUser.friendList!.pendingReceivedApproval?.append(meAsFriend)
                
                // set friend user as a friend item, and add them to user's sent requests
                if self.user!.friendList == nil { self.user!.friendList = FriendList() }
                if self.user!.friendList?.pendingSentApproval == nil { self.user!.friendList!.pendingSentApproval = [] }
                self.user!.friendList!.pendingSentApproval?.append(friend)
                
                do {
                    let myData = try FirebaseEncoder().encode(friendUser.friendList!.pendingReceivedApproval)
                    let friendData = try FirebaseEncoder().encode(self.user!.friendList!.pendingSentApproval)
                    // Write data to firebase
                    ref.child(FirebaseStructure.Users).child(friendUser.id!).child(FirebaseStructure.CharmUser.Friends).child(FirebaseStructure.CharmUser.FriendList.PendingReceivedApproval).setValue(myData) {
                        (error:Error?, ref:DatabaseReference) in
                        if let error = error {
                            print("~>Data could not be saved: \(error).")
                        } else {
                            print("~>Data saved successfully!")
                        }
                    }
                    
                    ref.child(FirebaseStructure.Users).child(self.user!.id!).child(FirebaseStructure.CharmUser.Friends).child(FirebaseStructure.CharmUser.FriendList.PendingSentApproval).setValue(friendData) {
                        (error:Error?, ref:DatabaseReference) in
                        if let error = error {
                            print("~>Data could not be saved: \(error).")
                        } else {
                            print("~>Data saved successfully!")
                        }
                    }
                    
                    alert.title = "Sent Request"
                    alert.message = "Your friend request has been sent.  Once the request has been approved by your friend, they will show up on your friends list."
                    DispatchQueue.main.async {
                        navVC.present(alert, animated: true, completion: nil)
                    }
                    
                    self.existingUsers.removeAll(where: { (existing) -> Bool in
                        return existing.email == friend.email
                    })
                    self.delegate?.updateTableView()
                } catch let error {
                    alert.title = "Request Failed"
                    alert.message = "Your friend request failed.  Please try again later."
                    print("~>Got an error: \(error)")
                    DispatchQueue.main.async {
                        navVC.present(alert, animated: true, completion: nil)
                    }
                    
                }
            }
        }
        
        
    }
    
    func sendTextRequest(toFriend friend: Friend) {
        
        // setup deep link
        guard let id = user?.id, let me = user?.userProfile, let url = URL(string: "https://blaumagier.com/friendinvite?id=\(id)") else { return }
        guard let deepComponents = DynamicLinkComponents(link: url, domainURIPrefix: FirebaseStructure.DeepLinks.PrefixURL) else {
            print("~>Unable to create deep components.")
            return }
        
        // start activity
        
        let window = UIApplication.shared.keyWindow!
        let viewActivity = UIActivityIndicatorView(style: .whiteLarge)
        viewActivity.center = window.center
        viewActivity.color = #colorLiteral(red: 0.1323429346, green: 0.1735357642, blue: 0.2699699998, alpha: 1)
        viewActivity.hidesWhenStopped = true
        
        window.addSubview(viewActivity)
        window.bringSubviewToFront(viewActivity)
        
        viewActivity.startAnimating()
        
        let iOSParams = DynamicLinkIOSParameters(bundleID: FirebaseStructure.DeepLinks.BundleID)
        iOSParams.minimumAppVersion = FirebaseStructure.DeepLinks.MinAppVersion
        iOSParams.appStoreID = FirebaseStructure.DeepLinks.AppStoreID
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
            
            // this should succeed 100% of the time, so user will never see this error
            guard let phone = friend.phone else {
                alert.title = "Error Adding Friend"
                alert.message = "Unable to add friend at this time.  Please restart the app and try again."
                navVC.present(alert, animated: true, completion: nil)
                viewActivity.stopAnimating()
                return
            }
            
            // setup message
            let composeVC = MFMessageComposeViewController()
            composeVC.messageComposeDelegate = self
            
            // Configure the fields of the interface.
            composeVC.recipients = [phone]
            var userName = ""
            if let user = self.user, let uid = user.id {
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
            do {
                let data = try FirebaseEncoder().encode(friendList)
                Database.database().reference().child(FirebaseStructure.Users).child(uid).child(FirebaseStructure.CharmUser.Friends).setValue(data) {
                    (error:Error?, ref:DatabaseReference) in
                    if let error = error {
                        print("~>Data could not be saved: \(error).")
                    } else {
                        print("~>Data saved successfully!")
                    }
                }
            } catch let error {
                print("~>There was an error trying to convert friendlist: \(error)")
            }
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
