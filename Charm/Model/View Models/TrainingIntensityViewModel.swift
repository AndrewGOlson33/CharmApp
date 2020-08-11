//
//  TrainingIntensityViewModel.swift
//  Charm
//
//  Created by Mobile Master on 7/19/20.
//  Copyright © 2020 Charm, LLC. All rights reserved.
//

import Foundation

class TrainingIntensityViewModel: NSObject {
    
    var phrases: [TrainingPhrase] = []
    
    var wordScore: TrainingScore {
        let wordScore = Float(phrases.compactMap { $0.wordCount }.reduce(0, +)) / Float(phrases.count)
        let score = wordScore / 25

        let label = wordScore > 5 ? String(format: "%.1f (Good)", wordScore) : String(format: "%.1f", wordScore)
        return TrainingScore(withScore: score.isNaN ? 0 : score, andLabel: label)
    }
    
    var specificScore: TrainingScore {
        let concreteScore = Float(phrases.compactMap { $0.concreteCount }.reduce(0, +)) / Float(phrases.count)
        let score = concreteScore / 3

        let label = concreteScore > 1 ? String(format: "%.1f (Good)", concreteScore) : String(format: "%.1f", concreteScore)
        return TrainingScore(withScore: score.isNaN ? 0 : score, andLabel: label)
    }
    
    var personalScore: TrainingScore {
        let firstScore = Float(phrases.compactMap { $0.firstCount }.reduce(0, +)) / Float(phrases.count)
        let secondScore = Float(phrases.compactMap { $0.secondCount }.reduce(0, +)) / Float(phrases.count)
        
        let score = secondScore / (firstScore + secondScore)
        
        let label = score.isNaN ? "0% Me || 0% You" : "\(Int((1 - score) * 100) + 1)% Me || \(Int(score * 100))% You"
        return TrainingScore(withScore: score.isNaN ? 0 : score, andLabel: label)
    }
    
    var emotionScore: TrainingScore {
        let positiveScore = Float(phrases.compactMap { $0.positiveScore }.reduce(0, +)) / Float(phrases.count)
        let negativeScore = Float(phrases.compactMap { $0.negativeScore }.reduce(0, +)) / Float(phrases.count)
        let score = positiveScore / (positiveScore + abs(negativeScore))

        let label = String(format: "%.1f Pos || %.1f Neg", positiveScore, negativeScore)
        return TrainingScore(withScore: score.isNaN ? 0 : score, andLabel: label)
    }
    
    // training model
    let model = FirebaseModel.shared.trainingModel
    
    var prompts: [ConversationPrompt] {
        return model?.conversationPrompts ?? []
    }
    
    var wordPrompts: [NounFlashcard] {
        return model?.concreteNounFlashcards ?? []
    }
    
    // MARK: - Functions
    
    func getPrompt() -> TrainingPrompt? {
        let lastFivePhrases = phrases.suffix(5)
        
        if lastFivePhrases.filter({$0.secondCount > 0}).count < 3 {
            return TrainingPrompt(withType: .connection, andPrompt: "Say Something About Them")
        } else if lastFivePhrases.filter({$0.positiveScore > 0}).count < 3 {
            return TrainingPrompt(withType: .positive, andPrompt: "Say Something Positive")
        } else if lastFivePhrases.filter({$0.concreteCount > 0}).count < 3 {
            return TrainingPrompt(withType: .specific, andPrompt: "Say Something Specific")
        } else if lastFivePhrases.filter({$0.firstCount > 0}).count < 3 {
            return TrainingPrompt(withType: .connection, andPrompt: "Say Something About Yourself")
        } else if lastFivePhrases.filter({$0.negativeScore > 0}).count < 4 {
            return TrainingPrompt(withType: .negative, andPrompt: "Say Something Negative")
        }
        
        return nil
    }
    
    func getRandomConversationPrompt() -> ConversationPrompt? {
        guard prompts.count > 0 else { return nil }
        return prompts[Int(arc4random_uniform(UInt32(prompts.count)))]
    }
    
    func getRandomWordPrompt() -> NounFlashcard? {
        guard wordPrompts.count > 0 else { return nil }
        return wordPrompts[Int(arc4random_uniform(UInt32(wordPrompts.count)))]
    }
    
    func addPhrase(_ text: String) {
        let phrase = TrainingPhrase(text: text)
        phrases.append(phrase)
    }
}

struct TrainingScore {
    
    var score: Float = 0
    var label: String = ""
    
    init(withScore score: Float, andLabel label: String) {
        self.score = score
        self.label = label
    }
}

struct TrainingPrompt {
    
    var phraseType: PhraseType = .specific
    var prompt: String = ""
    
    init(withType phraseType: PhraseType, andPrompt prompt: String) {
        self.phraseType = phraseType
        self.prompt = prompt
    }
}
