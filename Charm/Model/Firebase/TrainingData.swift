//
//  TrainingData.swift
//  Charm
//
//  Created by Daniel Pratt on 3/21/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import Foundation
import Firebase
import CodableFirebase

class TrainingModelCapsule {
    
    var model: TrainingData = TrainingData()
    
    init() {
        // start observing firebase
        observerFirebase()
    }
    
    func observerFirebase() {
        Database.database().reference().child(FirebaseStructure.Training.TrainingDatabase).observe(.value) { (snapshot) in
            guard let value = snapshot.value else { return }
        
            do {
                self.model = try FirebaseDecoder().decode(TrainingData.self, from: value)
                NotificationCenter.default.post(Notification(name: FirebaseNotification.TrainingModelLoaded))
            } catch let error {
                print("~>There was an error converting data: \(error)")
            }
        }
    }
    
    static var shared = TrainingModelCapsule()
    
}

struct TrainingData: Codable {
    var concreteNouns: [ConcreteNoun] = []
    var abstractNouns: [AbstractNoun] = []
    var converstaionPrompt: [ConversationPrompts] = []
}

struct ConcreteNoun: Codable {
    
    var word: String
    
    enum CodingKeys: String, CodingKey {
        case word = "X3"
    }
    
}

struct AbstractNoun: Codable {
    
    var word: String
    
    enum CodingKeys: String, CodingKey {
        case word = "X3"
    }
}

struct ConversationPrompts: Codable {
    var youSaid: String?
    var theySaid: String?
    
    enum CodingKeys: String, CodingKey {
        case youSaid = "You Said"
        case theySaid = "They Said"
    }
}
