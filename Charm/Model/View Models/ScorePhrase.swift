//
//  ScorePhrase.swift
//  Charm
//
//  Created by Daniel Pratt on 3/22/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import Foundation

class ScorePhraseModel: NSObject {
    
    let model = TrainingModelCapsule.shared
    
    func calculateScore(fromPhrase text: String) {
        
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
            if let tag = tag {
                let word = (text as NSString).substring(with: tokenRange)
                print("~>\(word): \(tag)")
                // append all words to wordlist
                wordCount += 1
                
                if checkConcrete(word: word) { concreteCount += 1 }
                if checkAbstract(word: word) { abstractCount += 1 }
                
                if tag.rawValue == "Pronoun" {
                    if checkFirstPerson(word: word) { firstCount += 1 }
                    if checkSecondPerson(word: word) { secondCount += 1 }
                }
                
                positiveScore += getPositiveScore(word: word)
                negativeScore += getNegativeScore(word: word)
            }
        }
        
        let score = getEstimatedPhraseStrength(length: wordCount, concrete: concreteCount, abstract: abstractCount, first: firstCount, second: secondCount)
        
        print("~>I counted: \(wordCount) words, and had a concrete count of: \(concreteCount), abstract count of: \(abstractCount), first count of: \(firstCount), second count of: \(secondCount), positive score: \(positiveScore), negative score: \(negativeScore) with an estimated phrase strength of: \(score)")
    }
    
    private func checkConcrete(word: String) -> Bool {
        return model.model.concreteNouns.contains(where: { (noun) -> Bool in
            return noun.word.lowercased() == word.lowercased()
        })
    }
    
    private func checkAbstract(word: String) -> Bool {
        return model.model.abstractNouns.contains(where: { (noun) -> Bool in
            return noun.word.lowercased() == word.lowercased()
        })
    }
    
    private func checkFirstPerson(word: String) -> Bool {
        return model.model.firstPersonLowercased.contains(word.lowercased())
    }
    
    private func checkSecondPerson(word: String) -> Bool {
        return model.model.secondPersonLowercased.contains(word.lowercased())
    }
    
    private func getPositiveScore(word: String) -> Int {
        if let word = model.model.positiveWords.first(where: { (scored) -> Bool in
            return word.lowercased() == scored.word.lowercased()
        }) {
            return word.score
        } else {
            return 0
        }
    }
    
    private func getNegativeScore(word: String) -> Int {
        if let word = model.model.negativeWords.first(where: { (scored) -> Bool in
            return word.lowercased() == scored.word.lowercased()
        }) {
            return word.score
        } else {
            return 0
        }
    }
    
    private func getEstimatedPhraseStrength(length: Int, concrete: Int, abstract: Int, first: Int, second: Int) -> Int {
        
        var score = 5
        score += length >= 7 ? 1 : 0
        score += concrete > 1 ? 1 : 0
        score += abstract > 1 ? 1 : 0
        score += second > 1 ? 1 : 0
        
        return score
        
    }
    
}
