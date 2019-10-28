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
    
    // setup variables
    var isSetupPhaseComplete = true
    
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
    
    init() {
        setupConnectionObserver()
        setupUserObserver()
        setupTrainingHistoryObserver()
        setupSnapshotObserver()
        setupTrainingModel()
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
                    self.handleCalls()
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
    
    private func handleCalls() {
        guard let user = charmUser, let call = user.currentCall else { return }
        print("~>Handling calls")
        NotificationCenter.default.post(name: FirebaseNotification.CharmUserHasCall, object: call)
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
}
