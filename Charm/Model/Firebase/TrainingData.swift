//
//  TrainingData.swift
//  Charm
//
//  Created by Daniel Pratt on 3/21/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import Foundation
import Firebase

enum WordType: String {
    case concrete = "Concrete"
    case abstract = "Abstract"
}

struct TrainingData: FirebaseItem {
    var id: String?
    var ref: DatabaseReference?
    var concreteNouns: [NounWord] = []
    var abstractNouns: [NounWord] = []
    var neutralWords: [NounFlashcard] = []
    var concreteNounFlashcards: [NounFlashcard] = []
    var abstractNounFlashcards: [NounFlashcard] = []
    
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
    var conversationPrompts: [ConversationPrompt] = []
    var unclassifiedNouns: [String]? = []
    
    // conversation phrases
    var conversationPhrases: ConversationPhrases?
    var phrasesLoaded: Bool = false
    
    init(snapshot: DataSnapshot) throws {
        guard snapshot.exists() else { throw FirebaseItemError.noSnapshot }
        id = snapshot.key
        ref = snapshot.ref
        
        let concreteSnap = snapshot.childSnapshot(forPath: "concreteNouns")
        for child in concreteSnap.children {
            guard let snapshot = child as? DataSnapshot else { continue }
            concreteNouns.append(try NounWord(snapshot: snapshot))
        }
        
        let abstractSnap = snapshot.childSnapshot(forPath: "abstractNouns")
        for child in abstractSnap.children {
            guard let snapshot = child as? DataSnapshot else { continue }
            abstractNouns.append(try NounWord(snapshot: snapshot))
        }
        
        let neutralSnap = snapshot.childSnapshot(forPath: "neutralWords")
        for child in neutralSnap.children {
            guard let snapshot = child as? DataSnapshot else { continue }
            neutralWords.append(try NounFlashcard(snapshot: snapshot))
        }
        
//        let concreteFlashSnap = snapshot.childSnapshot(forPath: "concreteNounFlashcards")
//        for child in concreteFlashSnap.children {
//            guard let snapshot = child as? DataSnapshot else { continue }
//            concreteNounFlashcards.append(try NounFlashcard(snapshot: snapshot))
//        }
//
//        let abstractFlashSnap = snapshot.childSnapshot(forPath: "abstractNounConcreteFlashcards")
//        for child in abstractFlashSnap.children {
//            guard let snapshot = child as? DataSnapshot else { continue }
//            abstractNounFlashcards.append(try NounFlashcard(snapshot: snapshot))
//        }
        
        if let firstPersonValues = snapshot.childSnapshot(forPath: "firstPerson").value as? [String] {
            for word in firstPersonValues {
                firstPerson.append(word)
            }
        }
        
        if let secondPersonValues = snapshot.childSnapshot(forPath: "secondPerson").value as? [String] {
            for word in secondPersonValues {
                secondPerson.append(word)
            }
        }
        
        let positiveSnap = snapshot.childSnapshot(forPath: "positiveWords")
        for child in positiveSnap.children {
            guard let snapshot = child as? DataSnapshot else { continue }
            positiveWords.append(try ScoredWord(snapshot: snapshot))
        }
        
        let negativeSnap = snapshot.childSnapshot(forPath: "negativeWords")
        for child in negativeSnap.children {
            guard let snapshot = child as? DataSnapshot else { continue }
            negativeWords.append(try ScoredWord(snapshot: snapshot))
        }
        
//        let promptSnap = snapshot.childSnapshot(forPath: "conversationPrompts")
//        for child in promptSnap.children {
//            guard let snapshot = child as? DataSnapshot else { continue }
//            conversationPrompts.append(try ConversationPrompt(snapshot: snapshot))
//        }
        
        // FIXME: REMOVE THIS - no phrases in video
//        let phrasesSnap = snapshot.childSnapshot(forPath: "conversationPhrases")
//        do {
//            conversationPhrases = try ConversationPhrases(snapshot: phrasesSnap)
//            phrasesLoaded = true
//        } catch let error {
//            print("~>Got an error loading conversation phrases: \(error)")
//            conversationPhrases = nil
//            phrasesLoaded = true
//        }
        
        if let unclassifiedValues = snapshot.childSnapshot(forPath: "unclassifiedNouns").value as? [String:String] {
            var unclass: [String] = []
            for word in unclassifiedValues.values {
                unclass.append(word)
            }
        
            unclassifiedNouns = unclass
        }
    }
    
    func toAny() -> [AnyHashable : Any] {
        return [:]
    }
    
    func save() {
        return
    }
}

struct NounFlashcard: FirebaseItem, Codable {
    var id: String?
    var ref: DatabaseReference?
    var word: String
    
    enum CodingKeys: String, CodingKey {
        case word = "X1"
    }
    
    init(snapshot: DataSnapshot) throws {
        guard snapshot.exists() else { throw FirebaseItemError.noSnapshot }
        guard let values = snapshot.value as? [String:String] else { throw FirebaseItemError.invalidData }
        id = snapshot.key
        ref = snapshot.ref
        
        word = values[CodingKeys.word.rawValue] ?? ""
    }
    
    func toAny() -> [AnyHashable : Any] {
        return [:]
    }
    
    func save() {
        return
    }
}

struct NounWord: FirebaseItem, Codable {
    var id: String?
    var ref: DatabaseReference?
    var word: String
    
    enum CodingKeys: String, CodingKey {
        case word = "X3"
    }
    
    init(snapshot: DataSnapshot) throws {
        guard snapshot.exists() else { throw FirebaseItemError.noSnapshot }
        guard let values = snapshot.value as? [String:String] else { throw FirebaseItemError.invalidData }
        id = snapshot.key
        ref = snapshot.ref
        
        word = values[CodingKeys.word.rawValue] ?? ""
    }
    
    func toAny() -> [AnyHashable : Any] {
        return [:]
    }
    
    func save() {
        return
    }
}

struct ConversationPhrases: FirebaseItem {
    var id: String?
    var ref: DatabaseReference?
    var specific: [ConversationPhrase] = []
    var connection: [ConversationPhrase] = []
    var positive: [ConversationPhrase] = []
    var negative: [ConversationPhrase] = []
    
    init(snapshot: DataSnapshot) throws {
        guard snapshot.exists() else { throw FirebaseItemError.noSnapshot }
        let specificSnap = snapshot.childSnapshot(forPath: "specific")
        let connectionSnap = snapshot.childSnapshot(forPath: "connection")
        let posSnap = snapshot.childSnapshot(forPath: "positive")
        let negSnap = snapshot.childSnapshot(forPath: "negative")
        
        do {
            specific = try getObjects(from: specificSnap)
            connection = try getObjects(from: connectionSnap)
            positive = try getObjects(from: posSnap)
            negative = try getObjects(from: negSnap)
        } catch let error {
            if let error = error as? FirebaseItemError { throw error } else { throw FirebaseItemError.invalidData }
        }
        
        id = snapshot.key
        ref = snapshot.ref
    }
    
    fileprivate func getObjects(from snapshot: DataSnapshot) throws -> [ConversationPhrase] {
        guard let values = snapshot.children.allObjects as? [DataSnapshot] else  { throw FirebaseItemError.invalidData }
        var phrases: [ConversationPhrase] = []
        
        for snap in values {
            do {
                let phrase = try ConversationPhrase(snapshot: snap)
                phrases.append(phrase)
            } catch let error {
                print("~>Specific value error: \(error)")
            }
        }
        
        return phrases
    }
    
    func toAny() -> [AnyHashable : Any] {
        return [:]
    }
}

struct ConversationPhrase: FirebaseItem {
    var id: String?
    var ref: DatabaseReference?
    var phrase: String
    
    init(snapshot: DataSnapshot) throws {
        guard snapshot.exists() else { throw FirebaseItemError.noSnapshot }
        guard let value = snapshot.value as? String else { throw FirebaseItemError.invalidData }
        
        id = snapshot.key
        ref = snapshot.ref
        phrase = value
    }
    
    func toAny() -> [AnyHashable : Any] {
        return [:]
    }
}

struct ConversationPrompt: FirebaseItem, Codable {
    var id: String?
    var ref: DatabaseReference?
    var prompt: String
    
    enum CodingKeys: String, CodingKey {
        case prompt = "prompt"
    }
    
    init(snapshot: DataSnapshot) throws {
        guard snapshot.exists() else { throw FirebaseItemError.noSnapshot }
        guard let values = snapshot.value as? [String:String] else { throw FirebaseItemError.invalidData }
        id = snapshot.key
        ref = snapshot.ref
        
        prompt = values[CodingKeys.prompt.rawValue] ?? ""
    }
    
    func toAny() -> [AnyHashable : Any] {
        return [:]
    }
    
    func save() {
        return
    }
}

struct ScoredWord: FirebaseItem, Codable {
    var id: String?
    var ref: DatabaseReference?
    var score: Int
    var word: String
    
    enum CodingKeys: String, CodingKey {
        case score = "score"
        case word = "word"
    }
    
    init(snapshot: DataSnapshot) throws {
        guard snapshot.exists() else { throw FirebaseItemError.noSnapshot }
        guard let values = snapshot.value as? [String:Any] else { throw FirebaseItemError.invalidData }
        id = snapshot.key
        ref = snapshot.ref
        
        score = values[CodingKeys.score.rawValue] as? Int ?? 0
        word = values[CodingKeys.word.rawValue] as? String ?? ""
    }
    
    func toAny() -> [AnyHashable : Any] {
        return [:]
    }
    
    func save() {
        return
    }
}

struct ChatScore {
    
    var score: Int = 0
    var position: Double = 0
    
    init(withScore score: Int, andPosition position: Double) {
        self.score = score
        self.position = position
    }
}
