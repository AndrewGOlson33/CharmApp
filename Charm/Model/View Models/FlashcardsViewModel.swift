//
//  FlashcardsViewModel.swift
//  Charm
//
//  Created by Daniel Pratt on 3/21/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import Foundation
import Firebase

enum FlashCardType {
    case concrete
    case emotions
}

enum Answer: String {
    case concrete
    case abstract
    case positive
    case negative
    case neutral
}

class FlashcardsViewModel: NSObject {
    
    // MARK: - Properties
    
    var trainingModel = FirebaseModel.shared.trainingModel
    var answer: Answer? = nil
    var answerString: String = ""
    var shouldShowNA: Bool = false
    
    var delegate: FlashcardsHistoryDelegate? = nil
    
    var delayUploadCount: Int = 0
    
    // MARK: Class Functions
    
    func getFlashCard(ofType type: FlashCardType = .concrete) -> String {
        guard let model = trainingModel else { fatalError("Training model is not loaded") }
        switch type {
        case .concrete:
            let random = Int(arc4random_uniform(2))
            if random == 0 {
                let randomIndex = Int(arc4random_uniform(UInt32(model.abstractNounFlashcards.count)))
                answer = .abstract
                print("~>Model count: \(model.abstractNounFlashcards.count) random index: \(randomIndex)")
                answerString = model.abstractNounFlashcards[randomIndex].word
                return answerString
            } else {
                let randomIndex = Int(arc4random_uniform(UInt32(model.concreteNounFlashcards.count)))
                answer = .concrete
                answerString = model.concreteNounFlashcards[randomIndex].word
                return answerString
            }
        case .emotions:
            let random = Int(arc4random_uniform(2))
            switch random {
            case 0:
                let randomIndex = Int(arc4random_uniform(UInt32(model.positiveWords.count)))
                answer = .positive
                answerString = model.positiveWords[randomIndex].word
                return answerString
            case 1:
                let randomIndex = Int(arc4random_uniform(UInt32(model.negativeWords.count)))
                answer = .negative
                answerString = model.negativeWords[randomIndex].word
                return answerString
            default:
                fatalError("~>Reached case in switch that should be impossible.")
            }
        }
        
        
    }
    
    func getResponse(answeredWith answer: Answer, forFlashcardType type: FlashCardType = .concrete) -> (response: String, correct: Bool) {
        guard let correct = self.answer else { fatalError("~>Answer was not set.") }
        if answer == self.answer {
            return ("Good Job!", true)
        } else {
            return ("Sorry, \(answerString) is \(correct.rawValue)", false)
        }
    }
    
    func getAverageConcreteScore(completion: @escaping(_ concreteHistory: TrainingStatistics) -> Void) {
        // have to do this in main, as app delegate may only be accessed in main
        let trainingHistory = FirebaseModel.shared.charmUser.trainingData
        if trainingHistory.concreteAverage.numQuestions == 0 {
            self.shouldShowNA = true
        } else {
            self.shouldShowNA = false
        }
        
        completion(trainingHistory.concreteAverage)
    }
    
    func getAverageEmotionsScore(completion: @escaping(_ emotionsHistory: TrainingStatistics) -> Void) {
        // have to do this in main, as app delegate may only be accessed in main
        let trainingHistory = FirebaseModel.shared.charmUser.trainingData
        if trainingHistory.emotionsAverage.numQuestions == 0 {
            self.shouldShowNA = true
        } else {
            self.shouldShowNA = false
        }
        
        completion(trainingHistory.emotionsAverage)
    }
    
    func calculateAverageScore(addingCorrect correct: Bool, toType type: FlashCardType = .concrete) {
        guard let user = FirebaseModel.shared.charmUser, let uid = user.id else { return }
        
        var trainingHistory = user.trainingData
        
        switch type {
        case .concrete:
            if correct {
                trainingHistory.concreteAverage.numCorrect += 1
                var record = trainingHistory.concreteAverage.correctRecord
                if record <= trainingHistory.concreteAverage.numCorrect {
                    record = trainingHistory.concreteAverage.numCorrect
                    trainingHistory.concreteAverage.correctRecord = record
                }
            } else {
                trainingHistory.concreteAverage.numCorrect = 0
            }
            
            
        case .emotions:
            if correct {
                trainingHistory.emotionsAverage.numCorrect += 1
                var record = trainingHistory.emotionsAverage.correctRecord
                if record <= trainingHistory.emotionsAverage.numCorrect {
                    record = trainingHistory.emotionsAverage.numCorrect
                    trainingHistory.emotionsAverage.correctRecord = record
                }
            } else {
                trainingHistory.emotionsAverage.numCorrect = 0
            }
        }
        
        FirebaseModel.shared.charmUser.trainingData = trainingHistory
        self.upload(trainingHistory: trainingHistory, forUid: uid)
    }
    
    func resetRecord(forType type: FlashCardType) {
        guard let user = FirebaseModel.shared.charmUser, let uid = user.id else { return }
        var trainingHistory = user.trainingData
        
        switch type {
        case .concrete:
            trainingHistory.concreteAverage.numCorrect = 0
            trainingHistory.concreteAverage.correctRecord = 1
        case .emotions:
            trainingHistory.emotionsAverage.numCorrect = 0
            trainingHistory.emotionsAverage.correctRecord = 1
        }
        
        FirebaseModel.shared.charmUser.trainingData = trainingHistory
        self.upload(trainingHistory: trainingHistory, forUid: uid)
    }

    // TODO: - Update this so it only calls once in a while
    fileprivate func upload(trainingHistory history: TrainingHistory, forUid uid: String) {
        delegate?.trainingHistoryUpdated()
        
        guard delayUploadCount == 3 else {
            delayUploadCount += 1
            return
        }
        
        delayUploadCount = 0
        
        DispatchQueue.global(qos: .utility).async {
            print("~>saving history")
            history.save()
        }
    }
    
}
