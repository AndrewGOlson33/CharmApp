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
        return scoreModel.strenth
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
    
    // training model
    let model = TrainingModelCapsule.shared
    var prompts: [ConversationPrompts] {
        return model.model.converstaionPrompt
    }
    
    // MARK: - Functions
    
    func getRandomConversationPrompt() -> ConversationPrompts? {
        guard prompts.count > 0 else { return nil }
        return prompts[Int(arc4random_uniform(UInt32(prompts.count)))]
    }
    
    func score(response text: String) {
        scoreModel.calculateScore(fromPhrase: text)
    }
    
}
