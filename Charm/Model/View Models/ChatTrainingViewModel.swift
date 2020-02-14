//
//  ChatTrainingViewModel.swift
//  Charm
//
//  Created by Daniel Pratt on 3/22/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import Foundation

class ChatTrainingViewModel: NSObject {
    
    // scoring model
    let scoreModel = ScorePhraseModel()
    
    // scores for populating scale bar data
    var strength: ChatScore {
        let score: Double = scoreModel.strenth.score >= 5 ? Double(scoreModel.strenth.score) : 5
        let position = (score - 5.0) / 5.0
        return ChatScore(withScore: scoreModel.strenth.score, andPosition: position)
    }
    
    var length: ChatScore {
        return scoreModel.length
    }
    
    var concrete: ChatScore {
        return scoreModel.concrete
    }
    
    var abstract: ChatScore {
        return scoreModel.abstract
    }
    
    var first: ChatScore {
        return scoreModel.first
    }
    
    var second: ChatScore {
        return scoreModel.second
    }
    
    var positive: ChatScore {
        return scoreModel.positive
    }
    
    var negative: ChatScore {
        return scoreModel.negative
    }
    
    var feedback: String {
        return scoreModel.comments
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
    
    func getRandomConversationPrompt() -> ConversationPrompt? {
        guard prompts.count > 0 else { return nil }
        return prompts[Int(arc4random_uniform(UInt32(prompts.count)))]
    }
    
    func getRandomWordPrompt() -> NounFlashcard? {
        guard wordPrompts.count > 0 else { return nil }
        return wordPrompts[Int(arc4random_uniform(UInt32(wordPrompts.count)))]
    }
    
    func score(response text: String) {
        scoreModel.calculateScore(fromPhrase: text)
    }
}
