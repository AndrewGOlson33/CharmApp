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
    
    // training model
    let model = TrainingModelCapsule.shared
    var prompts: [ConversationPrompts] {
        return model.model.converstaionPrompt
    }
    
    // MARK: - Functions
    
    func getRandomPrompt() -> ConversationPrompts? {
        guard prompts.count > 0 else { return nil }
        return prompts[Int(arc4random_uniform(UInt32(prompts.count)))]
    }
    
    func score(response text: String) {
        scoreModel.calculateScore(fromPhrase: text)
    }
    
}
