//
//  FlashcardsViewModel.swift
//  Charm
//
//  Created by Daniel Pratt on 3/21/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import Foundation
import Firebase
import CodableFirebase

enum FlashCardType {
    case Concrete
    case Emotions
}

enum Answer: String {
    case Concrete
    case Abstract
    case Positive
    case Negative
    case Neutral
}

class FlashcardsViewModel: NSObject {
    
    // MARK: - Properties
    
    var trainingModel = TrainingModelCapsule.shared
    var answer: Answer? = nil
    var answerString: String = ""
    var shouldShowNA: Bool = false
    
    // MARK: Class Functions
    
    func getFlashCard(ofType type: FlashCardType = .Concrete) -> String {
        
        switch type {
        case .Concrete:
            let random = Int(arc4random_uniform(2))
            if random == 0 {
                let randomIndex = Int(arc4random_uniform(UInt32(trainingModel.model.abstractNouns.count)))
                answer = .Abstract
                answerString = trainingModel.model.abstractNouns[randomIndex].word
                return answerString
            } else {
                let randomIndex = Int(arc4random_uniform(UInt32(trainingModel.model.concreteNouns.count)))
                answer = .Concrete
                answerString = trainingModel.model.concreteNouns[randomIndex].word
                return answerString
            }
        case .Emotions:
            let random = Int(arc4random_uniform(3))
            switch random {
            case 0:
                let randomIndex = Int(arc4random_uniform(UInt32(trainingModel.model.abstractNouns.count)))
                answer = .Neutral
                answerString = trainingModel.model.abstractNouns[randomIndex].word
                return answerString
            case 1:
                let randomIndex = Int(arc4random_uniform(UInt32(trainingModel.model.positiveWords.count)))
                answer = .Positive
                answerString = trainingModel.model.positiveWords[randomIndex].word
                return answerString
            case 2:
                let randomIndex = Int(arc4random_uniform(UInt32(trainingModel.model.negativeWords.count)))
                answer = .Negative
                answerString = trainingModel.model.negativeWords[randomIndex].word
                return answerString
            default:
                fatalError("~>Reached case in switch that should be impossible.")
            }
        }
        
        
    }
    
    func getResponse(answeredWith answer: Answer, forFlashcardType type: FlashCardType = .Concrete) -> (response: String, correct: Bool) {
        guard let correct = self.answer else { fatalError("~>Answer was not set.") }
        if answer == self.answer {
            return ("Good Job!", true)
        } else {
            return ("Sorry, \(answerString) is \(correct.rawValue)", false)
        }
    }
    
    func getAverageConcreteScore(completion: @escaping(_ concreteHistory: ConcreteTrainingHistory) -> Void) {
        // have to do this in main, as app delegate may only be accessed in main
        DispatchQueue.main.async {
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let user = delegate.user
            if let trainingHistory = user?.trainingData {
                if trainingHistory.concreteAverage.numQuestions == 0 {
                    self.shouldShowNA = true
                } else {
                    self.shouldShowNA = false
                }
                completion(trainingHistory.concreteAverage)
                
            } else {
                self.shouldShowNA = true
                completion(ConcreteTrainingHistory())
            }
        }
    }
    
    func getAverageEmotionsScore(completion: @escaping(_ emotionsHistory: EmotionsTrainingHistory) -> Void) {
        // have to do this in main, as app delegate may only be accessed in main
        DispatchQueue.main.async {
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let user = delegate.user
            if let trainingHistory = user?.trainingData {
                if trainingHistory.emotionsAverage.numQuestions == 0 {
                    self.shouldShowNA = true
                    
                } else {
                    self.shouldShowNA = false
                }
                
                completion(trainingHistory.emotionsAverage)
            } else {
                self.shouldShowNA = true
                completion(EmotionsTrainingHistory())
            }
        }
    }
    
    func calculateAverageScore(addingCorrect correct: Bool, toType type: FlashCardType = .Concrete) {
        // have to do this in main, as app delegate may only be accessed in main
        DispatchQueue.main.async {
            let delegate = UIApplication.shared.delegate as! AppDelegate
            guard let user = delegate.user, let uid = user.id else { return }
            
            var trainingHistory = user.trainingData != nil ? user.trainingData! : TrainingHistory()
            
            switch type {
            case .Concrete:
                trainingHistory.concreteAverage.numQuestions += 1
                if correct { trainingHistory.concreteAverage.numCorrect += 1 }
            case .Emotions:
                trainingHistory.emotionsAverage.numQuestions += 1
                if correct { trainingHistory.emotionsAverage.numCorrect += 1 }
            }
            
            self.upload(trainingHistory: trainingHistory, forUid: uid)
        }
    }

    
    fileprivate func upload(trainingHistory history: TrainingHistory, forUid uid: String) {
        do {
            let data = try FirebaseEncoder().encode(history)
            Database.database().reference().child(FirebaseStructure.Users).child(uid).child(FirebaseStructure.Training.TrainingDatabase).setValue(data)
        } catch let error {
            print("~>There was an error converting the data: \(error)")
        }
    }
    
}
