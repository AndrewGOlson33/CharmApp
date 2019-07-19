//
//  MainMenuViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 3/6/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase
import StoreKit

class MainMenuViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet var buttonViewGroup: [UIView]!
    
    // MARK: - Properties
    
    var isFirebaseConnected: Bool = true
    var firstSetup: Bool = true
    var loadingFriendFromNotification: Bool = false
    var checkedCredits: Bool = false
    
    // private vars for posting notifications
    private var shouldPostTrainingHistoryNotification: Bool = false
    
    // temp values
    var requestProd = SKProductsRequest()
    var products = [SKProduct]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup buttons
        setupButtons()
        
        // Setup loss of internet observer
        setupConnetionObserver()
        
        // Setup user observer
        setupUser()
        
        // Setup added friend observer
        NotificationCenter.default.addObserver(self, selector: #selector(addFriend(_:)), name: FirebaseNotification.GotFriendFromLink, object: nil)
        
        // Setup user's snapshot data observer
        setupDataObserver()
        
        // Setup user's training history observer
        setupTrainingHistoryObserver()
        
        // Upload Device Token
        uploadDeviceToken()
        
        // Start loading contacts list
        let _ = ContactsViewModel.shared.contacts
        
        validateProductIdentifiers()
        
        setupMetricsObserver()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard CharmUser.shared != nil else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.viewDidAppear(animated)
                return
            }
            return
        }
        
        if !self.loadingFriendFromNotification && !(UIApplication.shared.delegate as! AppDelegate).friendID.isEmpty {
            print("~>Going to add friend using id.")
            self.addFriend(withID: (UIApplication.shared.delegate as! AppDelegate).friendID)
        }
        
        checkCredits()
        checkStatus()
    }
    
    // MARK: - Private Setup Functions
    
    // Credits Update
    
    fileprivate func checkCredits () {
        let status = SubscriptionService.shared.updateCredits()
        print("~>Attempted to update credits and got status: \(status)")
        
        if !checkedCredits && (status == .receiptsNotLoaded || status == .userNotLoaded) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                self.checkedCredits = true
                self.checkCredits()
                return
            }
            return
        }
        
        checkedCredits = true
    }
    
    // Status Update
    
    fileprivate func checkStatus() {
        guard CharmUser.shared != nil && SubscriptionService.shared.receiptsCurrent else {
            SubscriptionService.shared.uploadReceipt()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.checkStatus()
                return
            }
            return
        }
        print("~>Checking status and have receipts.")
        print("~>Have a membership status of: \(CharmUser.shared.userProfile.membershipStatus)")
        if let subscription = SubscriptionService.shared.currentSubscription, !subscription.isActive {
            switch CharmUser.shared.userProfile.membershipStatus {
            case .currentSubscriber:
                CharmUser.shared.userProfile.membershipStatus = .formerSubscriber
                saveUserProfileToFirebase()
            case .unknown:
                CharmUser.shared.userProfile.membershipStatus = .notSubscribed
                saveUserProfileToFirebase()
            case .notSubscribed, .formerSubscriber:
                saveUserProfileToFirebase()
                return
            }
        } else if let subscription = SubscriptionService.shared.currentSubscription, !subscription.isActive {
            if CharmUser.shared.userProfile.membershipStatus != .currentSubscriber {
                CharmUser.shared.userProfile.membershipStatus = .currentSubscriber
                saveUserProfileToFirebase()
            }
        } else {
            if CharmUser.shared.userProfile.membershipStatus != .notSubscribed {
                CharmUser.shared.userProfile.membershipStatus = .notSubscribed
            }
        }
        
        
    }
    
    // Update status of user
    
    private func saveUserProfileToFirebase() {
        
        guard CharmUser.shared != nil, let id = CharmUser.shared.id else {
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 5.0) {
                self.saveUserProfileToFirebase()
                return
            }
            return
        }
        
        DispatchQueue.global(qos: .utility).async {
            let profile = CharmUser.shared.userProfile
            
            do {
                let data = try FirebaseEncoder().encode(profile)
                Database.database().reference().child(FirebaseStructure.Users).child(id).child(FirebaseStructure.CharmUser.Profile).setValue(data)
                print("~>Set user profile with new date")
            } catch let error {
                print("~>There was an error: \(error)")
            }
        }
    }
    
    // UI Related
    
    fileprivate func setupButtons() {
        for (index, button) in buttonViewGroup.enumerated() {
            
            button.layer.cornerRadius = 18
            button.layer.borderColor = UIColor.white.cgColor
            button.layer.borderWidth = 1.0
            button.layer.shadowColor = UIColor.black.cgColor
            button.layer.shadowOpacity = 0.6
            button.layer.shadowRadius = 8.0
            button.layer.shadowOffset = CGSize(width: 2, height: 2)
            button.alpha = 0.9
            
            var tap: UITapGestureRecognizer!
            
            switch index {
            case 0:
                tap = UITapGestureRecognizer(target: self, action: #selector(chatButtonTapped(_:)))
            case 1:
                tap = UITapGestureRecognizer(target: self, action: #selector(metricsButtonTapped(_:)))
            case 2:
                tap = UITapGestureRecognizer(target: self, action: #selector(learnButtonTapped(_:)))
            default:
                tap = UITapGestureRecognizer(target: self, action: #selector(trainButtonTapped(_:)))
            }
            
            button.addGestureRecognizer(tap)
            
        }
    }
    
    // Firebase Related
    
    fileprivate func setupConnetionObserver() {
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { connected in
            if let boolean = connected.value as? Bool, boolean == true {
                print("~>Connected")
                if !self.isFirebaseConnected {
                    if self.firstSetup { return }
                    self.showConnectionAlert()
                }
            } else {
                if self.firstSetup { return }
                self.showConnectionAlert()
            }
        })
    }
    
    fileprivate func showConnectionAlert() {
        DispatchQueue.main.async {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            if appDelegate.restoreFromBackground {
                appDelegate.restoreFromBackground = false
                return
            }
            
            self.isFirebaseConnected = !self.isFirebaseConnected
            let title = self.isFirebaseConnected ? "Connection Restored" : "Connection Lost"
            let message = self.isFirebaseConnected ? "Connection to the database server has been restored." : "Lost connection to databse server.  Please check your internet connection."
            
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.navigationController?.present(alert, animated: true, completion: nil)
        }
    }
    
    fileprivate func setupUser() {
        Database.database().reference().child(FirebaseStructure.Users).child(Auth.auth().currentUser!.uid).observe(.value) { (snapshot) in
            guard let value = snapshot.value else { return }
            DispatchQueue.main.async {
                do {
                    let user = try FirebaseDecoder().decode(CharmUser.self, from: value)
                    CharmUser.shared = user
                    // Post a notification that the user changed, along with the user obejct
                    NotificationCenter.default.post(name: FirebaseNotification.CharmUserDidUpdate, object: user)
                    // post training history notification if needed
                    if self.shouldPostTrainingHistoryNotification {
                        NotificationCenter.default.post(name: FirebaseNotification.TrainingHistoryUpdated, object: nil)
                        self.shouldPostTrainingHistoryNotification = false
                    }
                    // If there is a call, post a notification about that call
                    if let call = user.currentCall {
                        if call.status == .incoming {
                            NotificationCenter.default.post(name: FirebaseNotification.CharmUserIncomingCall, object: call)
                            DispatchQueue.main.async {
                                let delegate = UIApplication.shared.delegate as! AppDelegate
                                print("~>Incoming call status: \(delegate.incomingCall)")
                                if delegate.incomingCall {
                                    delegate.incomingCall = false
                                    self.setupIncoming(call: call)
                                    return
                                } else {
                                    let alert = UIAlertController(title: "Incoming Call", message: "You have an incoming call.", preferredStyle: .alert)
                                    alert.addAction(UIAlertAction(title: "Accept", style: .default, handler: { (_) in
                                        self.setupIncoming(call: call)
                                    }))
                                    alert.addAction(UIAlertAction(title: "Ignore", style: .cancel, handler: { _ in
                                        guard let call = CharmUser.shared.currentCall else { return }
                                        self.reject(call: call)
                                    }))
                                    self.navigationController?.present(alert, animated: true, completion: nil)
                                }
                            }
                        } else if self.firstSetup && call.status == .connected {
                            DispatchQueue.main.async {
                                let delegate = UIApplication.shared.delegate as! AppDelegate
                                if delegate.incomingCall {
                                    delegate.incomingCall = false
                                } else {
                                    delegate.removeActiveCalls()
                                }
                            }
                        } else if call.status == .rejected {
                            // remove the value first
                            if let videoVC = self.navigationController!.topViewController! as? VideoCallViewController {
                                videoVC.endCallButtonTapped(videoVC.btnEndCall!)
                            } else {
                                call.myCallRef.removeValue()
                            }
                            
                            let rejectedAlert = UIAlertController(title: "Unable to Place Call", message: "The person you are trying to reach is not available at this time.  Please try again later.", preferredStyle: .alert)
                            rejectedAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                            self.present(rejectedAlert, animated: true, completion: nil)
                        }
                    }
                    self.firstSetup = false
                    if (UIApplication.shared.delegate as! AppDelegate).showContactListFromNotification {
                        (UIApplication.shared.delegate as! AppDelegate).showContactListFromNotification = false
                        self.performSegue(withIdentifier: SegueID.FriendList, sender: self)
                    }
                } catch let error {
                    print("~>There was an error: \(error)")
                    return
                }
            }
        }
    }
    
    // Observes snapshot data
    fileprivate func setupDataObserver() {
        let snapShotRef = Database.database().reference().child(FirebaseStructure.Users).child(Auth.auth().currentUser!.uid).child(FirebaseStructure.CharmUser.Snapshot)
        SnapshotsLoading.shared.isLoading = true
        DispatchQueue.global(qos: .utility).async {
            snapShotRef.observe(.value) { (snapshot) in
                guard let values = snapshot.value as? [String:Any] else {
                    print("~>Couldn't convert values to [String:Any], possibly no data exists.")
                    SnapshotsLoading.shared.isLoading = false
                    return
                }
                SnapshotsLoading.shared.isLoading = true
                
                for value in values {
                    do {
                        let key = value.key
                        var snapshotData = try FirebaseDecoder().decode(Snapshot.self, from: value.value)
                        snapshotData.dateString = key
                        guard snapshotData.date != nil else { continue }
                        guard !UserSnapshotData.shared.snapshots.contains(where: { (snapshot) -> Bool in
                            snapshot.date == snapshotData.date
                        }) else { continue }
                        UserSnapshotData.shared.snapshots.append(snapshotData)
                    } catch let error {
                        print("~>Error getting snapshot data: \(error)")
                    }
                }
                
                SnapshotsLoading.shared.isLoading = false
            }
        }
        
    }
    
    // Observes Training History
    fileprivate func setupTrainingHistoryObserver() {
        let historyRef = Database.database().reference().child(FirebaseStructure.Users).child(Auth.auth().currentUser!.uid).child(FirebaseStructure.Training.TrainingDatabase)
        DispatchQueue.global(qos: .utility).async {
            historyRef.observe(.value) { (snapshot) in
                self.shouldPostTrainingHistoryNotification = true
            }
        }
        
    }
    
    fileprivate func reject(call: Call) {
        call.myCallRef.removeValue()
        
        let friendCall = Call(sessionID: call.sessionID, status: .rejected, from: Auth.auth().currentUser!.uid, in: call.room)
        
        DispatchQueue.global(qos: .utility).async {
            do {
                let data = try FirebaseEncoder().encode(friendCall)
                call.friendCallRef.setValue(data)
            } catch let error {
                print("~>There was an error converting call data: \(error)")
            }
        }
        
    }
    
    fileprivate func setupIncoming(call: Call) {
        DispatchQueue.main.async {
            let myUser = CharmUser.shared
            guard let friend = myUser?.friendList?.currentFriends?.first(where: { (friend) -> Bool in
                friend.id! == call.fromUserID
            }) else {
                let connectionError = UIAlertController(title: "Error", message: "There was an error connecting your call.  Do you want to try again?", preferredStyle: .alert)
                connectionError.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
                connectionError.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (_) in
                    self.setupIncoming(call: call)
                    return
                }))
                self.present(connectionError, animated: true, completion: nil)
                return
            }
            
            let callVC = self.storyboard?.instantiateViewController(withIdentifier: StoryboardID.VideoCall) as! VideoCallViewController
            callVC.myUser = myUser
            callVC.friend = friend
            callVC.kSessionId = call.sessionID
            callVC.room = call.room
            
            self.navigationController?.pushViewController(callVC, animated: true)
        }
    }
    
    fileprivate func setupMetricsObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(metricsButtonTapped(_:)), name: FirebaseNotification.NewSnapshot, object: nil)
    }
    
    // MARK: - Upload User's Token For APNS Notifications
    
    fileprivate func uploadDeviceToken() {
        DispatchQueue.global(qos: .utility).async {
            InstanceID.instanceID().instanceID { (result, error) in
                if let error = error {
                    print("~>Error fetching remote instance ID: \(error)")
                } else if let result = result {
                    
                    print("~>Remote instance ID token: \(result.token)")
                    if var user = CharmUser.shared, let id = user.id {
                        if user.tokenID == nil {
                            user.tokenID = [result.token : true]
                        } else if !user.tokenID!.contains(where: { (token) -> Bool in
                            return token.key == result.token
                        }) {
                            user.tokenID![result.token] = true
                        } else {
                            // there is no need to be redundant, so just return
                            return
                        }
                        print("~>User token set to: \(String(describing: user.tokenID))")
                        Database.database().reference().child(FirebaseStructure.Users).child(id).child(FirebaseStructure.CharmUser.Token).setValue(user.tokenID)
                    }
                }
            }
        }
        
    }
    
    
    // MARK: - Button Handling
    
    @objc func chatButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: SegueID.Chat, sender: self)
    }
    
    @objc func metricsButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: SegueID.MetricsTab, sender: self)
    }
    
    @objc func learnButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: SegueID.VideoTraining, sender: self)
    }
    
    @objc func trainButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: SegueID.TrainingTab, sender: self)
    }
    
    // MARK: - Prepare For Segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("~>Going to segue with id: \(String(describing: segue.identifier)) and destination: \(segue.destination))")
        if segue.identifier == SegueID.FriendList, let friendsVC = segue.destination as? FriendListTableViewController {
            friendsVC.showContacts = false
        }
    }
    
    // MARK: - Add Friend From Deep Link
    
    @objc fileprivate func addFriend(_ notification: Notification) {
        loadingFriendFromNotification = true
        guard let id = notification.object as? String else { return }
        addFriend(withID: id)
    }
    
    fileprivate func addFriend(withID id: String) {
        DispatchQueue.global(qos: .utility).async {
            // first move friend from received to current friends
            guard var user = CharmUser.shared else { return }
            
            if user.friendList?.currentFriends == nil { user.friendList?.currentFriends = [] }
            
            if user.friendList?.currentFriends?.contains(where: { (friend) -> Bool in
                return friend.id == id
            }) ?? false {
                // friend already exists in list
                let alert = UIAlertController(title: "Already Friends", message: "You are trying to add a friend that already exists in your contact list.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.navigationController?.present(alert, animated: true, completion: nil)
                return
            } else if user.friendList?.pendingSentApproval?.contains(where: { (friend) -> Bool in
                return friend.id == id
            }) ?? false {
                // friend already exists in list
                let alert = UIAlertController(title: "Already Have Pending Request", message: "You have already sent this user a friend request.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.navigationController?.present(alert, animated: true, completion: nil)
                return
            } else if user.friendList?.pendingReceivedApproval?.contains(where: { (friend) -> Bool in
                return friend.id == id
            }) ?? false {
                // friend already exists in list
                let alert = UIAlertController(title: "Already Have Pending Request", message: "You already have a pending friend request from this user.  Please approve the request on your contacts list.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                
                DispatchQueue.main.async {
                    self.navigationController?.present(alert, animated: true, completion: nil)
                }
                
                return
            }
            
            // write data to firebase
            
            // finally move user from sent to current friends on friend's friend list'
            guard let myID = user.id else { return }
            
            Database.database().reference().child(FirebaseStructure.Users).child(id).observeSingleEvent(of: .value) { (snapshot) in
                guard let value = snapshot.value else { return }
                // get the user object
                var friendUser = try! FirebaseDecoder().decode(CharmUser.self, from: value)
                if friendUser.friendList?.currentFriends == nil { friendUser.friendList?.currentFriends = [] }
                let friendObject = Friend(id: id, first: friendUser.userProfile.firstName, last: friendUser.userProfile.lastName, email: friendUser.userProfile.email)
                let meAsFriend = Friend(id: myID, first: user.userProfile.firstName, last: user.userProfile.lastName, email: user.userProfile.email)
                
                friendUser.friendList?.currentFriends?.append(meAsFriend)
                user.friendList?.currentFriends?.append(friendObject)
                
                // write changes to firebase
                do {
                    let friendCurrent = try FirebaseEncoder().encode(friendUser.friendList!.currentFriends!)
                    let myCurrent = try FirebaseEncoder().encode(user.friendList!.currentFriends!)
                    Database.database().reference().child(FirebaseStructure.Users).child(id).child(FirebaseStructure.CharmUser.Friends).child(FirebaseStructure.CharmUser.FriendList.CurrentFriends).setValue(friendCurrent)
                    
                    Database.database().reference().child(FirebaseStructure.Users).child(myID).child(FirebaseStructure.CharmUser.Friends).child(FirebaseStructure.CharmUser.FriendList.CurrentFriends).setValue(myCurrent)
                    
                    self.loadingFriendFromNotification = false
                    (UIApplication.shared.delegate as! AppDelegate).friendID = ""
                    
                } catch let error {
                    print("~>Got an error: \(error)")
                }
            }
        }
    }

}

extension MainMenuViewController: SKProductsRequestDelegate {
    
    func validateProductIdentifiers() {
        let productsRequest = SKProductsRequest(productIdentifiers: Set(["com.charismaanalytics.Charm.sub.fiveTokens.monthly", "com.charismaanalytics.Charm.sub.threetokens.monthly"]))
        
        // Keep a strong reference to the request.
        self.requestProd = productsRequest
        productsRequest.delegate = self
        productsRequest.start()
    }
    
    // SKProductsRequestDelegate protocol method
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        
        self.products = response.products
        
        for invalidIdentifier in response.invalidProductIdentifiers {
            print("~>Invalid ID: \(invalidIdentifier)")
        }
        
    }
}
