//
//  MainTabBarController.swift
//  Charm
//
//  Created by Игорь on 06.0520..
//  Copyright © 2020 Charm, LLC. All rights reserved.
//

import UIKit
import Firebase
import FirebaseInstanceID
import StoreKit


class MainTabBarController: UITabBarController {
    
    // MARK: - Properties
    
    var firebaseModel = FirebaseModel.shared
    
    var firstSetup: Bool = true
    var loadingFriendFromNotification: Bool = false
    var checkedCredits: Bool = false
    
    // temp values
    var requestProd = SKProductsRequest()
    var products = [SKProduct]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self
        
        if #available(iOS 13.0, *) {
            
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithOpaqueBackground()
            navBarAppearance.accessibilityTextualContext = .sourceCode
            navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white, .font : UIFont.boldSystemFont(ofSize: 19)]
            navBarAppearance.backgroundImage = UIImage(named: "header")
            
            
            self.navigationController?.navigationBar.standardAppearance = navBarAppearance
            self.navigationController?.navigationBar.compactAppearance = navBarAppearance
            self.navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        }
          
          // Upload Device Token
          uploadDeviceToken()
          
          // Start loading contacts list
          let _ = ContactsViewModel.shared.contacts
          
          validateProductIdentifiers()
          setupMetricsObserver()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Setup added friend observer
        NotificationCenter.default.addObserver(self, selector: #selector(addFriend(_:)), name: FirebaseNotification.GotFriendFromLink, object: nil)
        
        // Setup open friend list observer
        NotificationCenter.default.addObserver(self, selector: #selector(addFriend(_:)), name: FirebaseNotification.showContactListFromNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !self.loadingFriendFromNotification && !(UIApplication.shared.delegate as! AppDelegate).friendID.isEmpty {
            print("~>Going to add friend using id.")
            self.addFriend(withID: (UIApplication.shared.delegate as! AppDelegate).friendID)
        }
        
        checkCredits()
        checkStatus()
        
        print("~>Firebase user uid: ", FirebaseModel.shared.charmUser.id ?? "Undefined")
    }
    
    // MARK: - Private Setup Functions
    
    // Credits Update
    
    fileprivate func checkCredits () {
        let status = SubscriptionService.shared.updateCredits()
        print("~>Attempted to update credits and got status: \(status)")
        
        if !checkedCredits && (status == .receiptsNotLoaded || status == .userNotLoaded) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
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
        guard firebaseModel.charmUser != nil && SubscriptionService.shared.receiptsCurrent else {
            SubscriptionService.shared.uploadReceipt()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.checkStatus()
                return
            }
            return
        }
        print("~>Checking status and have receipts.")
        print("~>Have a membership status of: \(firebaseModel.charmUser.userProfile.membershipStatus)")
        if let subscription = SubscriptionService.shared.currentSubscription, !subscription.isActive {
            switch firebaseModel.charmUser.userProfile.membershipStatus {
            case .currentSubscriber:
                firebaseModel.charmUser.userProfile.membershipStatus = .formerSubscriber
                firebaseModel.charmUser.save()
            case .unknown:
                firebaseModel.charmUser.userProfile.membershipStatus = .notSubscribed
                firebaseModel.charmUser.save()
            case .notSubscribed, .formerSubscriber:
                firebaseModel.charmUser.save()
                return
            }
        } else if let subscription = SubscriptionService.shared.currentSubscription, !subscription.isActive {
            if firebaseModel.charmUser.userProfile.membershipStatus != .currentSubscriber {
                firebaseModel.charmUser.userProfile.membershipStatus = .currentSubscriber
                firebaseModel.charmUser.save()
            }
        } else {
            if firebaseModel.charmUser.userProfile.membershipStatus != .notSubscribed {
                firebaseModel.charmUser.userProfile.membershipStatus = .notSubscribed
            }
        }
    }
    
    // Firebase Related
    
    fileprivate func setupConnectionObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleConnectionAlert(_:)), name: FirebaseNotification.connectionStatusChanged, object: nil)
    }
    
    @objc fileprivate func handleConnectionAlert(_ notification: Notification) {
        guard let status = notification.object as? Bool else { print("~>No status"); return }
        showConnectionAlert(status: status)
    }
    
    fileprivate func showConnectionAlert(status: Bool) {
        DispatchQueue.main.async {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            if appDelegate.restoreFromBackground {
                appDelegate.restoreFromBackground = false
                return
            }
            
            let title = status ? "Connection Restored" : "Connection Lost"
            let message = status ? "Connection to the database server has been restored." : "Lost connection to databse server.  Please check your internet connection."
            
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.navigationController?.present(alert, animated: true, completion: nil)
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
                    if var user = self.firebaseModel.charmUser, let id = user.id {
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
                        Database.database().reference().child(FirebaseStructure.usersLocation).child(id).child(FirebaseStructure.CharmUser.token).setValue(user.tokenID)
                    }
                }
            }
        }
    }
    
    // MARK: - Button Handling
    
    @objc func chatButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: SegueID.chat, sender: self)
    }
    
    @objc func metricsButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: SegueID.metricsTab, sender: self)
    }
    
    @objc func learnButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: SegueID.videoTraining, sender: self)
    }
    
    @objc func trainButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: SegueID.trainingTab, sender: self)
    }
    
    // MARK: - Prepare For Segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueID.friendList, let friendsVC = segue.destination as? FriendListTableViewController {
            friendsVC.showContacts = false
        }
    }
    
    // MARK: - Add Friend From Deep Link
    
    @objc fileprivate func addFriend(_ notification: Notification) {
        loadingFriendFromNotification = true
        guard let id = notification.object as? String else { return }
        addFriend(withID: id)
    }
    
    @objc fileprivate func showFriendListFrom(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.performSegue(withIdentifier: SegueID.friendList, sender: self)
        }
    }
    
    fileprivate func addFriend(withID id: String) {
        
        // first move friend from received to current friends
        guard var user = self.firebaseModel.charmUser else { return }
        
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
        
        Database.database().reference().child(FirebaseStructure.usersLocation).child(id).observeSingleEvent(of: .value) { (snapshot) in
            
            // get the user object
            var friendUser = try! CharmUser(snapshot: snapshot)
            if friendUser.friendList?.currentFriends == nil { friendUser.friendList?.currentFriends = [] }
            let friendObject = Friend(id: id, first: friendUser.userProfile.firstName, last: friendUser.userProfile.lastName, email: friendUser.userProfile.email)
            let meAsFriend = Friend(id: myID, first: user.userProfile.firstName, last: user.userProfile.lastName, email: user.userProfile.email)
            
            friendUser.friendList?.currentFriends?.append(meAsFriend)
            FirebaseModel.shared.charmUser.friendList?.currentFriends?.append(friendObject)
            
            // write changes to firebase
            let friendCurrent = friendUser.friendList!.toAny()
            let myCurrent = FirebaseModel.shared.charmUser.friendList!.toAny()
            
            
            Database.database().reference().child(FirebaseStructure.usersLocation).child(id).child(FirebaseStructure.CharmUser.friendListLocation).setValue(friendCurrent)  { (error, _) in
                print(error ?? "Success added")
            }
            
            Database.database().reference().child(FirebaseStructure.usersLocation).child(myID).child(FirebaseStructure.CharmUser.friendListLocation).setValue(myCurrent) { (error, _) in
                print(error ?? "Success added")
            }
            
            self.loadingFriendFromNotification = false
            (UIApplication.shared.delegate as! AppDelegate).friendID = ""
        }
    }
}


extension MainTabBarController: SKProductsRequestDelegate {
    
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


extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        let tabBarIndex = tabBarController.selectedIndex
        switch tabBarIndex {
        case 0:
            navigationItem.title = "SELECT YOUR PARTNER"
        case 1:
             navigationItem.title = "YOUR CALLS"
        case 2:
             navigationItem.title = "SELECT A TUTORIAL"
        case 3:
             navigationItem.title = "SELECT YOUR PARTNER"
        case 4:
             navigationItem.title = "SETTINGS"
        default:
            break
        }
     }
}
