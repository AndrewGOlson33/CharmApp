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

class FlashcardsViewModel: NSObject {
    
    // MARK: - Properties
    
    var trainingModel = TrainingModelCapsule()
    var answerIsConcrete: Bool = false
    var answerString: String = ""
    var shouldShowNA: Bool = false
    
    // MARK: Class Functions
    
    func getFlashCard() -> String {
        let random = Int(arc4random_uniform(2))
        if random == 0 {
            let randomIndex = Int(arc4random_uniform(UInt32(trainingModel.model.abstractNouns.count)))
            answerIsConcrete = false
            answerString = trainingModel.model.abstractNouns[randomIndex].word
            return answerString
        } else {
            let randomIndex = Int(arc4random_uniform(UInt32(trainingModel.model.concreteNouns.count)))
            answerIsConcrete = true
            answerString = trainingModel.model.concreteNouns[randomIndex].word
            return answerString
        }
    }
    
    func getResponse(answeredConcrete: Bool) -> (response: String, correct: Bool) {
        if answerIsConcrete == answeredConcrete {
            return ("Good Job!", true)
        } else {
            let value = answerIsConcrete == true ? "Concrete Noun" : "Abstract Noun"
            return ("Sorry, \(answerString) is a \(value)", false)
        }
    }
    
    func getAverageScore(completion: @escaping(_ concreteHistory: ConcreteTrainingHistory) -> Void) {
        // have to do this in main, as app delegate may only be accessed in main
        DispatchQueue.main.async {
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let user = delegate.user
            if let trainingHistory = user?.trainingData {
                print("~>Got training history data.")
                if trainingHistory.concreteAverage.numQuestions == 0 { self.shouldShowNA = true }
                completion(trainingHistory.concreteAverage)
                self.shouldShowNA = false
            } else {
                self.shouldShowNA = true
                completion(ConcreteTrainingHistory())
            }
        }
    }
    
    func calculateAverageScore(addingCorrect correct: Bool) {
        // have to do this in main, as app delegate may only be accessed in main
        DispatchQueue.main.async {
            let delegate = UIApplication.shared.delegate as! AppDelegate
            guard let user = delegate.user, let uid = user.id else { return }
            if var trainingHistory = user.trainingData {
                trainingHistory.concreteAverage.numQuestions += 1
                if correct { trainingHistory.concreteAverage.numCorrect += 1 }
                self.upload(trainingHistory: trainingHistory, forUid: uid)
            } else {
                var trainingHistory = TrainingHistory()
                trainingHistory.concreteAverage.numQuestions += 1
                if correct { trainingHistory.concreteAverage.numCorrect += 1 }
                self.upload(trainingHistory: trainingHistory, forUid: uid)
            }
            
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
