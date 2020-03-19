//
//  FirebaseModel.swift
//  Charm
//
//  Created by Daniel Pratt on 10/28/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import Foundation
import Firebase

class FirebaseModel {
    
    // shared model
    static let shared = FirebaseModel()
    
    // constants
    var constants: FirebaseConstants!
    
    // setup variables
    var isSetupPhaseComplete = false
    
    // training model
    var trainingModel: TrainingData!
    var isTrainingModelLoaded: Bool {
        guard let trainingModel = trainingModel else { return false }
        return trainingModel.abstractNounFlashcards.count > 0 && trainingModel.concreteNounFlashcards.count > 0 && trainingModel.conversationPrompts.count > 0 && trainingModel.negativeWords.count > 0 && trainingModel.positiveWords.count > 0
    }
    
    // user items
    var charmUser: CharmUser!
    
    // snapshots
    var snapshots: [Snapshot] = [] {
        didSet {
            snapshots.sort { (lhs, rhs) -> Bool in
                lhs.date ?? Date.distantPast > rhs.date ?? Date.distantPast
            }
            
            NotificationCenter.default.post(name: FirebaseNotification.SnapshotLoaded, object: nil)
        }
    }
    var selectedSnapshot: Snapshot? = nil
    var isSnapshotSample: Bool {
        return snapshots.count == 0
    }
    
    // contacts
    var meAsFriend: Friend? {
        guard let id = charmUser.id, let user = charmUser else { return nil }
        let profile = user.userProfile
        return Friend(id: id, first: profile.firstName, last: profile.lastName, email: profile.email, phone: profile.phone)
    }
    
    init() {
        setupConnectionObserver()
        setupUserObserver()
        setupTrainingHistoryObserver()
        setupSnapshotObserver()
        setupTrainingModel()
        setupCallObserver()
        setupConstants()
    }
    
    // MARK: - Connection Observer
    
    private func setupConnectionObserver() {
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        DispatchQueue.global(qos: .utility).async { [weak self] in
            connectedRef.observe(.value, with: { [weak self] connected in
                guard let self = self else { return }
                if self.isSetupPhaseComplete, let status = connected.value as? Bool {
                    NotificationCenter.default.post(name: FirebaseNotification.connectionStatusChanged, object: status)
                }
            })
        }
    }
    
    // MARK: - User Observer
    
    private func setupUserObserver() {
        guard let authUser = Auth.auth().currentUser else { return }
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            
            Database.database().reference().child(FirebaseStructure.usersLocation).child(authUser.uid).observe(.value) { [weak self] (snapshot) in
                guard let self = self else { return }
                do {
                    // set the user and notify listeners that user has updated
                    self.charmUser = try CharmUser(snapshot: snapshot)
                    NotificationCenter.default.post(name: FirebaseNotification.CharmUserDidUpdate, object: self.charmUser)
                } catch let error {
                    print("~>There was an error: \(error)")
                    return
                }
            }
        }
    }
    
    // MARK: - Snapshots Observer
    
    private func setupSnapshotObserver() {
        guard let authUser = Auth.auth().currentUser else { return }
        SnapshotsLoading.shared.isLoading = true
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            Database.database().reference().child(FirebaseStructure.usersLocation).child(authUser.uid).child(FirebaseStructure.CharmUser.snapshotLocation).observe(.value) { [weak self] (snapshot) in
                guard let self = self else { return }
                guard snapshot.exists() else { print("~>No snapshots, perhaps no data exists"); return }
                do {
                    for child in snapshot.children {
                        guard let snapshot = child as? DataSnapshot else { continue }
                        guard !self.snapshots.contains(where: { (existing) -> Bool in
                            existing.id == snapshot.key
                        }) else { continue }
                        self.snapshots.append(try Snapshot(snapshot: snapshot))
                    }
                    
                    SnapshotsLoading.shared.isLoading = false
                    if let first = self.snapshots.first { self.selectedSnapshot = first }
                    NotificationCenter.default.post(name: FirebaseNotification.SnapshotLoaded, object: nil)
                } catch let error {
                    print("~>There was an error: \(error)")
                    SnapshotsLoading.shared.isLoading = false
                    return
                }
            }
        }
    }
    
    // MARK: - Training History Observer
    
    private func setupTrainingHistoryObserver() {
        guard let authUser = Auth.auth().currentUser else { return }
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            Database.database().reference().child(FirebaseStructure.usersLocation).child(authUser.uid).child(FirebaseStructure.Training.trainingDatabase).observe(.childChanged) { [weak self] (_) in
                guard self != nil else { return }
                print("~>Training history updated")
                NotificationCenter.default.post(name: FirebaseNotification.trainingHistoryUpdated, object: nil)
            }
        }
    }
    
    // MARK: - Call handler
    
    private func setupCallObserver() {
        guard let authUser = Auth.auth().currentUser else { return }
        Database.database().reference().child(FirebaseStructure.usersLocation).child(authUser.uid).child(FirebaseStructure.CharmUser.currentCallLocation).observe(.value) { [weak self] (snapshot) in
            guard let self = self else { return }
            guard snapshot.exists() else {
                if !self.isSetupPhaseComplete { self.isSetupPhaseComplete = true }
                return
            }
            do {
                let call = try Call(snapshot: snapshot)
                self.handle(call: call)
                if !self.isSetupPhaseComplete { self.isSetupPhaseComplete = true }
            } catch let error {
                print("~>There was an error trying to capture the call: \(error)")
            }
        }
        
    }
    
    private func handle(call: Call) {
        switch call.status {
        case .incoming:
            handleIncoming(call)
        case .connected:
            handleConnected(call)
        case .rejected:
            handleRejected(call)
        default:
            print("~>Status: \(call.status)")
            return
        }
    }
    
    private func handleIncoming(_ call: Call) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let delegate = UIApplication.shared.delegate as? AppDelegate else { return }
            guard let user = self.charmUser, let fl = user.friendList, let cf = fl.currentFriends, let friend = cf.first(where: { (friend) -> Bool in
                friend.id == call.fromUserID
            }) else { return }
            if delegate.incomingCall {
                delegate.incomingCall = false
                self.setupIncoming(call: call, with: friend)
                return
            } else {
                self.showIncomingCallAlert(forCall: call, from: friend)
            }
        }
    }
    
    private func handleConnected(_ call: Call) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.isSetupPhaseComplete else { return }
            guard let delegate = UIApplication.shared.delegate as? AppDelegate else { return }
            if delegate.incomingCall { delegate.incomingCall = false } else { delegate.removeActiveCalls() }
        }
    }
    
    private func handleRejected(_ call: Call) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let delegate = UIApplication.shared.delegate as? AppDelegate else { return }
           guard let window = delegate.window, let navVC = window.rootViewController as? UINavigationController else {
               DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                   guard let self = self else { return }
                   self.handleRejected(call)
               }
               return
           }
            
            if let videoVC = navVC.topViewController as? VideoCallViewController {
                videoVC.endCallButtonTapped(videoVC.btnEndCall!)
            } else {
                call.myCallRef.removeValue()
            }
            
            let rejectedAlert = UIAlertController(title: "Unable to Place Call", message: "The person you are trying to reach is not available at this time.  Please try again later.", preferredStyle: .alert)
            rejectedAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            navVC.present(rejectedAlert, animated: true, completion: nil)
        }
    }
    
    private func showIncomingCallAlert(forCall call: Call, from friend: Friend) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let delegate = UIApplication.shared.delegate as? AppDelegate else { return }
            guard let window = delegate.window, let navVC = window.rootViewController as? UINavigationController else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    guard let self = self else { return }
                    self.showIncomingCallAlert(forCall: call, from: friend)
                }
                return
            }
            
            let alert = UIAlertController(title: "Incoming Call", message: "You have an incoming call from \(friend.firstName) \(friend.lastName)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Accept", style: .default, handler: { [weak self] (_) in
                guard let self = self else { return }
                self.setupIncoming(call: call, with: friend)
            }))
            alert.addAction(UIAlertAction(title: "Ignore", style: .cancel, handler: { [weak self] (_) in
                guard let self = self else { return }
                self.rejectIncoming(call: call, from: friend)
            }))
            
            navVC.present(alert, animated: true, completion: nil)
        }
    }
    
    private func setupIncoming(call: Call, with friend: Friend) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let delegate = UIApplication.shared.delegate as? AppDelegate else { return }
            guard let window = delegate.window, let navVC = window.rootViewController as? UINavigationController else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    guard let self = self else { return }
                    self.setupIncoming(call: call, with: friend)
                }
                return
            }
            
            let callVC = navVC.storyboard?.instantiateViewController(withIdentifier: StoryboardID.videoCall) as! VideoCallViewController
            guard let myUser = self.charmUser else { return }
            callVC.myUser = myUser
            callVC.friend = friend
            callVC.kSessionId = call.sessionID
            callVC.room = call.room
            navVC.pushViewController(callVC, animated: true)
        }
    }
    
    private func rejectIncoming(call: Call, from friend: Friend) {
        call.myCallRef.removeValue()
        var friendCall = Call(sessionID: call.sessionID, status: .rejected, from: Auth.auth().currentUser!.uid, in: call.room)
        friendCall.ref = call.friendCallRef
        friendCall.save()
    }
    
    // MARK: - Training Model
    
    private func setupTrainingModel() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            Database.database().reference().child(FirebaseStructure.Training.trainingDatabase).observe(.value) { [weak self] (snapshot) in
                guard let self = self else { return }
                do {
                    self.trainingModel = try TrainingData(snapshot: snapshot)
                    NotificationCenter.default.post(name: FirebaseNotification.trainingModelLoaded, object: nil)
                } catch let error {
                    print("~>There was an error: \(error)")
                    return
                }
            }
        }
    }
    
    func checkType(of word: String) -> WordType {
        
        if trainingModel.abstractNouns.contains(where: { (abstract) -> Bool in
            return abstract.word.lowercased() == word.lowercased()
        }) {
            return .abstract
        }
        
        if trainingModel.concreteNouns.contains(where: { (concrete) -> Bool in
            return concrete.word.lowercased() == word.lowercased()
        }) {
            return .concrete
        }
        
        // add to the unknown list
        uploadUnclassified(nouns: [word])
        return .concrete
    }
    
    func checkTypes(from wordChoices: [IdeaEngagement], completion: @escaping(_ wordTypes: [WordType]) -> Void) {
        
        var unclassified: [String] = []
        var types: [WordType] = []
        
        for word in wordChoices {
            if trainingModel.abstractNouns.contains(where: { (abstract) -> Bool in
                return abstract.word.lowercased() == word.word.lowercased()
            }) {
                types.append(.abstract)
                continue
            } else if trainingModel.concreteNouns.contains(where: { (concrete) -> Bool in
                return concrete.word.lowercased() == word.word.lowercased()
            }) {
                types.append(.concrete)
            } else {
                types.append(.concrete)
                unclassified.append(word.word)
            }
        }
        
        // add to the unknown list
        
        if unclassified.count > 0 {
            uploadUnclassified(nouns: unclassified)
        }
        
        completion(types)
    }
    
    private func uploadUnclassified(nouns: [String]) {
        var upload: [String] = []
        if let existing = trainingModel.unclassifiedNouns {
            upload = existing
            for word in nouns {
                if !existing.contains(word.lowercased()) { upload.append(word.lowercased()) }
            }
        } else {
            upload = nouns.map { $0.lowercased() }
        }
        
        DispatchQueue.global(qos: .utility).async {
            Database.database().reference().child(FirebaseStructure.Training.trainingDatabase).child(FirebaseStructure.Training.unclassifiedNouns).setValue(upload)
        }
    }
    
    // MARK: - Setup Consants
    private func setupConstants() {
        DispatchQueue.global(qos: .utility).async {
            Database.database().reference().child(FirebaseStructure.constants).observeSingleEvent(of: .value) { [weak self] (snapshot) in
                guard let self = self else { return }
                do {
                    self.constants = try FirebaseConstants(snapshot: snapshot)
                } catch let error {
                    print("~>There was an error loading the app constants: \(error)")
                }
            }
        }
    }
}
