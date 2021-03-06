//
//  ScorePhrase.swift
//  Charm
//
//  Created by Daniel Pratt on 3/22/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class ScorePhraseModel: NSObject {
    
    // Enum for Score Type
    
    enum ChatScoreCategory {
        case strength
        case length
        case concrete
        case abstract
        case first
        case second
        case positive
        case negative
    }
    
    // training data model
    let model = FirebaseModel.shared.trainingModel
    
    // public scored properties
    public private(set) var strenth = ChatScore(withScore: 0, andPosition: 0)
    public private(set) var length = ChatScore(withScore: 0, andPosition: 0)
    public private(set) var concrete = ChatScore(withScore: 0, andPosition: 0)
    public private(set) var abstract = ChatScore(withScore: 0, andPosition: 0)
    public private(set) var first = ChatScore(withScore: 0, andPosition: 0)
    public private(set) var second = ChatScore(withScore: 0, andPosition: 0)
    public private(set) var positive = ChatScore(withScore: 0, andPosition: 0)
    public private(set) var negative = ChatScore(withScore: 0, andPosition: 0)
    public private(set) var unclassified: Int = 0
    public private(set) var repeatedWords: Int = 0
    public private(set) var comments: String = ""
    private var words: [String] = []
    private var unclassifiedArray: [String] = []
    
    func calculateScore(fromPhrase text: String) {
        
        unclassified = 0
        repeatedWords = 0
        unclassifiedArray = []
        
        let tagger = NSLinguisticTagger(tagSchemes: [.lexicalClass], options: 0)
        tagger.string = text
        let range = NSRange(location: 0, length: text.utf16.count)
        let optionsTagger: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace]
        
        var wordCount: Int = 0
        var concreteCount: Int = 0
        var abstractCount: Int = 0
        var firstCount: Int = 0
        var secondCount: Int = 0
        var positiveScore: Int = 0
        var negativeScore: Int = 0
        
        tagger.enumerateTags(in: range, unit: .word, scheme: .lexicalClass, options: optionsTagger) { tag, tokenRange, _ in

            let word = (text as NSString).substring(with: tokenRange)
            // append all words to wordlist
            wordCount += 1
            
            var classified = false
            
            if checkConcrete(word: word) {
                concreteCount += 1
                classified = true
            }
            if checkAbstract(word: word) {
                abstractCount += 1
                classified = true
            }
            
            if !classified, let tag = tag, tag.rawValue == "Noun" {
                unclassified += 1
                unclassifiedArray.append(word)
                concreteCount += 1 // scoring as concrete for now
            }
            
            if checkFirstPerson(word: word) { firstCount += 1 }
            if checkSecondPerson(word: word) { secondCount += 1 }
            
            positiveScore += getPositiveScore(word: word)
            negativeScore += getNegativeScore(word: word)
            
            if words.contains(word) { repeatedWords += 1 }
            words.append(word)
        }
        
        let score = getEstimatedPhraseStrength(length: wordCount, concrete: concreteCount, first: firstCount, second: secondCount, pos: positiveScore, neg: negativeScore)
        
        
        strenth = getChatScore(for: .strength, withScore: score)
        length = getChatScore(for: .length, withScore: wordCount)
        concrete = getChatScore(for: .concrete, withScore: concreteCount)
        abstract = getChatScore(for: .abstract, withScore: abstractCount)
        first = getChatScore(for: .first, withScore: firstCount)
        second = getChatScore(for: .second, withScore: secondCount)
        positive = getChatScore(for: .positive, withScore: positiveScore)
        negative = getChatScore(for: .negative, withScore: negativeScore)
        
        print("~>Score: \(score)")
        
        // determine comment string
        if score == 10 {
            comments = "Comments:\nGreat job! You talked about me and you. Clearly communicated your ideas and shared your emotions."
        } else if wordCount < 7 {
            comments = "Comments:\nCharm noticed your phrase length was under 7 words. This suggests you are not adding enough to the conversation. Try saying more things."
        }  else if concreteCount == 0 {
            comments = "Comments:\nCharm noticed you didn't use any concrete words. This suggests others might not understand what you are saying. Try saying more concrete words."
        } else if secondCount == 0 {
            comments = "Comments:\nCharm noticed you didn't use any second person \"you\" pronouns. This suggests you are focusing the converation on \"me\" instead of \"you and me\". Try adding a second person \"you\" pronoun."
        } else if firstCount == 0 {
            comments = "Comments:\nCharm noticed you didn't use any first person \"I\" pronouns. This suggests you are focusing the converation on \"you\" instead of \"you and me\". Try adding a first person \"I\" pronoun."
        } else if abs(negativeScore) + positiveScore < 4 {
            comments = "Comments:\nCharm noticed you didn't use any emotional words. This suggests you are being \"nice\". Try mentioning some good things or some bad things."
        } else if negativeScore + positiveScore < 0 {
            comments = "Comments: Charm noticed you used negative emotional words. Try mentioning some good things with the bad things."
        }
        
        print("~>I counted: \(wordCount) words, and had a concrete count of: \(concreteCount), abstract count of: \(abstractCount), first count of: \(firstCount), second count of: \(secondCount), positive score: \(positiveScore), negative score: \(negativeScore) with an estimated phrase strength of: \(score), and \(unclassified) unclassified words.")
        
        if unclassified > 0 { uploadUnclassified(nouns: unclassifiedArray) }
    }
    
    private func uploadUnclassified(nouns: [String]) {
        var upload: [String] = []
        if let model = model, let existing = model.unclassifiedNouns {
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
    
    private func checkConcrete(word: String) -> Bool {
        return model?.concreteNouns.contains(where: { (noun) -> Bool in
            return noun.word.lowercased() == word.lowercased()
        }) ?? false
    }
    
    private func checkAbstract(word: String) -> Bool {
        return model?.abstractNouns.contains(where: { (noun) -> Bool in
            return noun.word.lowercased() == word.lowercased()
        }) ?? false
    }
    
    private func checkFirstPerson(word: String) -> Bool {
        return model?.firstPersonLowercased.contains(word.lowercased()) ?? false
    }
    
    private func checkSecondPerson(word: String) -> Bool {
        return model?.secondPersonLowercased.contains(word.lowercased()) ?? false
    }
    
    private func getPositiveScore(word: String) -> Int {
        if let word = model?.positiveWords.first(where: { (scored) -> Bool in
            return word.lowercased() == scored.word.lowercased()
        }) {
            return word.score
        } else {
            return 0
        }
    }
    
    private func getNegativeScore(word: String) -> Int {
        if let word = model?.negativeWords.first(where: { (scored) -> Bool in
            return word.lowercased() == scored.word.lowercased()
        }) {
            return word.score
        } else {
            return 0
        }
    }
    
    private func getEstimatedPhraseStrength(length: Int, concrete: Int, first: Int, second: Int, pos: Int, neg: Int) -> Int {
        
        var score = 5
        score += length >= 7 ? 1 : 0
        score += concrete >= 1 ? 1 : 0
        score += first >= 1 ? 1 : 0
        score += second >= 1 ? 1 : 0
        score += pos + abs(neg) >= 4 ? 1 : 0
        score += pos + neg <= -3 ? -6 : 0
        
        return score >= 5 ? score : 5
    }
    
    // Creates a new object that is accessed externally
    private func getChatScore(for category: ChatScoreCategory, withScore score: Int) -> ChatScore {
        return ChatScore(withScore: score, andPosition: getScorePercent(score: score, category: category))
    }
    
    // helper function to calculate position percent
    private func getScorePercent(score: Int, category: ChatScoreCategory) -> Double {
        
        switch category {
        case .strength:
            return Double(score) / 10.0
        case .length:
            let percent = Double(score) / 15.0
            return percent > 1 ? 1 : percent
        case .positive, .negative:
            let percent = Double(abs(score)) / 4.0
            return percent > 1 ? 1 : percent
        default:
            let percent = Double(score) / 2.0
            return percent > 1 ? 1 : percent
        }
    }
}
