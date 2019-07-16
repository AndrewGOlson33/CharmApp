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

enum WordType: String {
    case Concrete = "Concrete"
    case Abstract = "Abstract"
}

class TrainingModelCapsule {
    
    var model: TrainingData = TrainingData()
    var isModelLoaded: Bool {
        return model.abstractNounConcreteFlashcards.count > 0 && model.concreteNounFlashcards.count > 0 && model.converstaionPrompt.count > 0 && model.negativeWords.count > 0 && model.positiveWords.count > 0
    }
    
    init() {
        // start observing firebase
        observerFirebase()
    }
    
    func observerFirebase() {
        print("~>Observing firebase training")
        Database.database().reference().child(FirebaseStructure.Training.TrainingDatabase).observeSingleEvent(of: .value) { (snapshot) in
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
    
    func checkType(of word: String) -> WordType {
        
        if model.abstractNouns.contains(where: { (abstract) -> Bool in
            return abstract.word.lowercased() == word.lowercased()
        }) {
            return .Abstract
        }
        
        if model.concreteNouns.contains(where: { (concrete) -> Bool in
            return concrete.word.lowercased() == word.lowercased()
        }) {
            return .Concrete
        }
        
        // add to the unknown list
        uploadUnclassified(nouns: [word])
        return .Concrete
    }
    
    func checkTypes(from wordChoices: [IdeaEngagement], completion: @escaping(_ wordTypes: [WordType]) -> Void) {
        
        var unclassified: [String] = []
        var types: [WordType] = []
        
        for word in wordChoices {
            if model.abstractNouns.contains(where: { (abstract) -> Bool in
                return abstract.word.lowercased() == word.word.lowercased()
            }) {
                types.append(.Abstract)
                continue
            } else if model.concreteNouns.contains(where: { (concrete) -> Bool in
                return concrete.word.lowercased() == word.word.lowercased()
            }) {
                types.append(.Concrete)
            } else {
                types.append(.Concrete)
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
        if let existing = model.unclassifiedNouns {
            upload = existing
            for word in nouns {
                if !existing.contains(word.lowercased()) { upload.append(word.lowercased()) }
            }
        } else {
            upload = nouns.map { $0.lowercased() }
        }
        
        DispatchQueue.global(qos: .utility).async {
            Database.database().reference().child(FirebaseStructure.Training.TrainingDatabase).child(FirebaseStructure.Training.UnclassifiedNouns).setValue(upload)
        }
    }
    
}

struct TrainingData: Codable {
    var concreteNouns: [ConcreteNoun] = []
    var abstractNouns: [AbstractNoun] = []
    var neutralWords: [NeutralWord] = []
    var concreteNounFlashcards: [ConcreteNounFlashcard] = []
    var abstractNounConcreteFlashcards: [AbstractNounFlashcard] = []
    var firstPerson: [String] = []
    var firstPersonLowercased: [String] {
        return firstPerson.map {$0.lowercased()}
    }
    var secondPerson: [String] = []
    var secondPersonLowercased: [String] {
        return secondPerson.map {$0.lowercased()}
    }
    var positiveWords: [ScoredWord] = []
    var negativeWords: [ScoredWord] = []
    var converstaionPrompt: [ConversationPrompts] = []
    var unclassifiedNouns: [String]? = []
}

struct ConcreteNounFlashcard: Codable {
    var word: String
    
    enum CodingKeys: String, CodingKey {
        case word = "X1"
    }
}

struct AbstractNounFlashcard: Codable {
    var word: String
    
    enum CodingKeys: String, CodingKey {
        case word = "X1"
    }
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

struct NeutralWord: Codable {
    var word: String
    
    enum CodingKeys: String, CodingKey {
        case word = "X1"
    }
}

struct PositiveWord: Codable {
    var word: String
    
    enum CodingKeys: String, CodingKey {
        case word = "X3"
    }
}

struct NegativeWord: Codable {
    var word: String
    
    enum CodingKeys: String, CodingKey {
        case word = "X3"
    }
}

struct ConversationPrompts: Codable {
    var youSaid: String?
    var theySaid: String
    
    enum CodingKeys: String, CodingKey {
        case youSaid = "You Said"
        case theySaid = "They Said"
    }
}

struct ScoredWord: Codable {
    var score: Int
    var word: String
}

struct ChatScore {
    
    var score: Int = 0
    var position: Double = 0
    
    init(withScore score: Int, andPosition position: Double) {
        self.score = score
        self.position = position
    }
    
}
