//
//  TrainingPhrase.swift
//  Charm
//
//  Created by Mobile Master on 7/19/20.
//  Copyright © 2020 Charm, LLC. All rights reserved.
//

import UIKit
import Firebase

class TrainingPhrase: NSObject {
    // training data model
    let model = FirebaseModel.shared.trainingModel
    
    public private(set) var text: String!
    public private(set) var wordCount: Int = 0
    public private(set) var concreteCount: Int = 0
    public private(set) var firstCount: Int = 0
    public private(set) var secondCount: Int = 0
    public private(set) var positiveScore: Int = 0
    public private(set) var negativeScore: Int = 0
    
    init(text: String) {
        super.init()
        calculateCounts(from: text)
    }
    
    func calculateCounts(from text: String) {
        self.text = text
        let tagger = NSLinguisticTagger(tagSchemes: [.lexicalClass], options: 0)
        tagger.string = text
        let range = NSRange(location: 0, length: text.utf16.count)
        let optionsTagger: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace]
        
        tagger.enumerateTags(in: range, unit: .word, scheme: .lexicalClass, options: optionsTagger) { tag, tokenRange, _ in

            let word = (text as NSString).substring(with: tokenRange)
            // append all words to wordlist
            wordCount += 1
            
            var classified = false
            
            if checkConcrete(word: word) {
                concreteCount += 1
                classified = true
            }
            
            if !classified, let tag = tag, tag.rawValue == "Noun" {
                concreteCount += 1 // scoring as concrete for now
            }
            
            if checkFirstPerson(word: word) { firstCount += 1 }
            if checkSecondPerson(word: word) { secondCount += 1 }
            
            positiveScore += getPositiveScore(word: word)
            negativeScore += getNegativeScore(word: word)
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
}
