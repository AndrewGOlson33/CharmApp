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
        delegate?.updateTableView()
        setupAddFriendsArrays()
    }
    
    // MARK: - Data Access
    
    func configureCell(atIndex index: Int, withCell cell: ChatFriendListTableViewCell) -> ChatFriendListTableViewCell {
        
        let friend = currentFriends[index]
        
        cell.lblName.text = "\(friend.firstName) \(friend.lastName)"
        cell.lblEmail.text = friend.email
        
        // check to see if contacts has an image
        
        if let image = getPhoto(forFriend: friend) {
            cell.imgProfile.image = image
        } else {
            cell.imgProfile.image = UIImage(named: "icnTempProfile")
        }
        
        return cell
    }
    
    func configureCell(atIndex index: Int, withCell cell: FriendListTableViewCell, forType type: ContactType, filtered: Bool) -> FriendListTableViewCell {
        
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
            cell.lblDetail.text = "Invite to Charm"
            cell.btnApprove.setTitle("+ Add", for: .normal)
            cell.btnApprove.isHidden = false
            cell.addMethod = .Phone
        }
        
        // configure cell data
        cell.lblName.text = "\(friend.firstName) \(friend.lastName)"
        cell.lblEmail.text = type == .AddByPhone ? friend.phone! : friend.email
        
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
                    }) else { return }
                    
                    friendsFriendlist.remove(at: index)
                    
                    // now encode and save data
                    let myFriendData = try FirebaseEncoder().encode(myNewFriends)
                    let friendsData = try FirebaseEncoder().encode(friendsFriendlist)
                    
                    myRef.setValue(myFriendData)
                    friendRef.setValue(friendsData)
                } catch let error {
                    print("~>There was an error converting friend lists to delete: \(error)")
                }
            })
            
        }
        
    }
    
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
    
    func sendTextRequest(toFriend friend: Friend) {
        let navVC = (UIApplication.shared.delegate as! AppDelegate).window!.rootViewController as! UINavigationController
        let alert = UIAlertController(title: "", message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        
        guard MFMessageComposeViewController.canSendText() else {
            alert.title = "Error Adding Friend"
            alert.message = "This device is not setup for sending text messages."
            return
        }
        
        // this should succeed 100% of the time, so user will never see this error
        guard let phone = friend.phone else {
            alert.title = "Error Adding Friend"
            alert.message = "Unable to add friend at this time.  Please restart the app and try again."
            return
        }
        
        // setup message
        let composeVC = MFMessageComposeViewController()
        composeVC.messageComposeDelegate = self
        
        // Configure the fields of the interface.
        composeVC.recipients = [phone]
        let url = "https://www.blaumagier.com"
        composeVC.body = "Click the link to add me as a friend on Charm, the app that teaches you how to be more charming!  If you don't have Charm, the link will open the App Store page so you can download it first.\n\(url)"
        
        // Present the view controller modally.
        navVC.present(composeVC, animated: true, completion: nil)
    }
    
}

extension ContactsViewModel: MFMessageComposeViewControllerDelegate {
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        
        // Dismiss the message compose view controller.
        controller.dismiss(animated: true, completion: nil)
    }
    
}
