//
//  CreatingConversationViewModel.swift
//  Charm
//
//  Created by Daniel Pratt on 2/3/20.
//  Copyright © 2020 Charm, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol LevelUpDelegate {
    func updated(progress: Double)
    func updated(level: Int, detail: String)
}

enum LoadStatus {
    case loaded, loading, failed
}

enum PhraseType {
    case specific, connection, positive, negative
}

enum ScoreStatus {
    case complete, incomplete
}

struct PhraseInfo {
    let phrase: String
    let type: PhraseType
}

struct PhraseScore {
    let feedback: String
    let formattedText: NSAttributedString
    let status: ScoreStatus
}

class CreatingConversationViewModel: NSObject {
    
    // Model Objects
    let phrases = FirebaseModel.shared.trainingModel.conversationPhrases
    var level = FirebaseModel.shared.charmUser.trainingData.conversationLevel
    
    // Important Model Variables
    var loadStatus: LoadStatus {
        if FirebaseModel.shared.trainingModel.phrasesLoaded && phrases != nil { return .loaded }
        else if FirebaseModel.shared.trainingModel.phrasesLoaded && phrases == nil { return .loading }
        else { return .failed }
    }
    
    var currentLevel: Int {
        didSet {
            delegate?.updated(level: currentLevel, detail: level.levelDetail)
        }
    }
    
    var progress: Double {
        didSet {
            delegate?.updated(progress: progress)
        }
    }
    
    var progressText: String {
        return "\(Int(progress * 100))%"
    }
    
    // Delegate
    var delegate: LevelUpDelegate?
    
    // Available Phrases
    
    fileprivate var specific: [ConversationPhrase] = []
    fileprivate var connection: [ConversationPhrase] = []
    fileprivate var positive: [ConversationPhrase] = []
    fileprivate var negative: [ConversationPhrase] = []
    
    // Model for scoring
    fileprivate let concreteWords: [NounWord] = FirebaseModel.shared.trainingModel.concreteNouns
    fileprivate let firstPersonWords: [String] = FirebaseModel.shared.trainingModel.firstPerson
    fileprivate let secondPersonWords: [String] = FirebaseModel.shared.trainingModel.secondPerson
    fileprivate let positiveWords: [ScoredWord] = FirebaseModel.shared.trainingModel.positiveWords
    fileprivate let negativeWords: [ScoredWord] = FirebaseModel.shared.trainingModel.negativeWords
    
    override init() {
        currentLevel = level.currentLevel
        progress = level.progress
        super.init()
        loadPhrases()
    }
    
    // MARK: - Setup Functions
    
    fileprivate func loadPhrases() {
        switch loadStatus {
        case .loaded:
            loadSpecific()
            loadConnection()
            loadPositive()
            loadNegative()
        case .loading:
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self else { return }
                self.loadPhrases()
                return
            }
            return
        case .failed:
            print("~>Failed to load")
            return
        }
    }
    
    fileprivate func loadSpecific() {
        guard loadStatus == .loaded, let phrases = self.phrases else { return }
        specific = phrases.specific
    }
    
    fileprivate func loadConnection() {
        guard loadStatus == .loaded, let phrases = self.phrases else { return }
        connection = phrases.connection
    }
    
    fileprivate func loadPositive() {
        guard loadStatus == .loaded, let phrases = self.phrases else { return }
        positive = phrases.positive
    }
    
    fileprivate func loadNegative() {
        guard loadStatus == .loaded, let phrases = self.phrases else { return }
        negative = phrases.negative
    }
    
    // MARK: - Interactive Methods
    
    func getPrompt() -> PhraseInfo {
        let type = getType()
        let phrase: String
        
        switch type {
        case .specific:
            if specific.count < 1 { loadSpecific() }
            phrase = specific.remove(at: Int.random(in: 0...specific.count)).phrase
        case .connection:
            if connection.count < 1 { loadConnection() }
            phrase = connection.remove(at: Int.random(in: 0...connection.count)).phrase
        case .positive:
            if positive.count < 1 { loadPositive() }
            // why is positive not working?
            phrase = positive.remove(at: Int.random(in: 0...positive.count)).phrase
        case .negative:
            if negative.count < 1 { loadNegative() }
            phrase = negative.remove(at: Int.random(in: 0...negative.count)).phrase
        }
        
        return PhraseInfo(phrase: phrase, type: type)
    }
    
    // MARK: - Priavte Phrase Setup Methods
    
    fileprivate func getType() -> PhraseType {
        let random = Int.random(in: 1...100)
        switch random {
        case 1...10:
            return .negative
        case 11...40:
            return .positive
        case 41...65:
            return .connection
        default:
            return .specific
        }
    }
    
    // MARK: Scoring Model
    
    func getScore(for phrase: PhraseInfo, completion: @escaping(_ score: PhraseScore) -> Void) {
        let score: PhraseScore
        switch phrase.type {
        case .specific:
            score = scoreSpecific(phrase: phrase)
        case .connection:
            score = scoreConnection(phrase: phrase)
        case .positive:
            score = scorePositive(phrase: phrase)
        case .negative:
            score = scoreNegative(phrase: phrase)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            guard let self = self else { return }
            completion(score)
            if self.currentLevel != self.level.currentLevel { self.currentLevel = self.level.currentLevel }
            self.progress = self.level.progress
        }
    }
    
    private func scoreSpecific(phrase: PhraseInfo) -> PhraseScore {
        var words: [String] = []
        let highlightedPhrase: NSMutableAttributedString = NSMutableAttributedString()
        
        for (index, current) in phrase.phrase.components(separatedBy: " ").enumerated() {
            let attributes: [NSAttributedString.Key : Any]
            if concreteWords.contains(where: { $0.word.lowercased() == current.lowercased() }) {
                words.append(current)
                attributes = [
                    .foregroundColor : UIColor.black,
                    .backgroundColor : #colorLiteral(red: 0.6784313725, green: 0.5803921569, blue: 0, alpha: 1)
                ]
            } else {
                attributes = [.foregroundColor : UIColor.black]
            }
            
            let currentWord = NSAttributedString(string: current, attributes: attributes)
            highlightedPhrase.append(currentWord)
            if index < (phrase.phrase.count - 1) { highlightedPhrase.append(NSAttributedString(string: " ")) }
        }
        
        switch words.count {
        case 0:
            return PhraseScore(feedback: "We're sorry, we were unable to detect a specific concrete word. Try again.\n(Examples: duck, train, David)", formattedText: highlightedPhrase, status: .incomplete)
        case 1:
            return PhraseScore(feedback: "Great Job! \(words[0]) is a specific word!", formattedText: highlightedPhrase, status: .complete)
        default:
            var feedback: String = "Great Job! "
            let lastIndex = words.count - 1
            let andIndex = words.count - 2
            
            for (index, current) in words.enumerated() {
                feedback.append("\(current), ")
                if index == andIndex { feedback.append("and ") } else if index == lastIndex { feedback.append("are specific words!") }
            }
            
            return PhraseScore(feedback: feedback, formattedText: highlightedPhrase, status: .complete)
        }
    }
    
    private func scoreConnection(phrase: PhraseInfo) -> PhraseScore {
        var firstWords: [String] = []
        var secondWords: [String] = []
        let highlightedPhrase: NSMutableAttributedString = NSMutableAttributedString()
        
        for (index, current) in phrase.phrase.components(separatedBy: " ").enumerated() {
            let attributes: [NSAttributedString.Key : Any]
            if firstPersonWords.contains(where: { $0.lowercased() == current.lowercased() }) {
                firstWords.append(current)
                attributes = [
                    .foregroundColor : UIColor.black,
                    .backgroundColor : #colorLiteral(red: 0.1490196078, green: 0.5254901961, blue: 0.4862745098, alpha: 1)
                ]
            } else if secondPersonWords.contains(where: { $0.lowercased() == current.lowercased() }) {
                 secondWords.append(current)
                 attributes = [
                     .foregroundColor : UIColor.black,
                     .backgroundColor : #colorLiteral(red: 0.4756349325, green: 0.4756467342, blue: 0.4756404161, alpha: 1)
                 ]
            } else {
                attributes = [.foregroundColor : UIColor.black]
            }
            
            let currentWord = NSAttributedString(string: current, attributes: attributes)
            highlightedPhrase.append(currentWord)
            if index < (phrase.phrase.count - 1) { highlightedPhrase.append(NSAttributedString(string: " ")) }
        }
        
        switch (firstWords.count, secondWords.count ) {
        case (0, 0):
            return PhraseScore(feedback: "We're sorry, we were unable to detect any first or second person words. Try again.\n(Examples: I(first), You(second))", formattedText: highlightedPhrase, status: .incomplete)
        case (1, 0):
            return PhraseScore(feedback: "\(firstWords[0]) is a first person word, but you also need to include at least one second person word.\n(Example: You)", formattedText: highlightedPhrase, status: .incomplete)
        case (0, 1):
            return PhraseScore(feedback: "\(secondWords[0]) is a second person word, but you also need to include at least one first person word.\n(Example: Me)", formattedText: highlightedPhrase, status: .incomplete)
        case (1, 1):
            return PhraseScore(feedback: "Great Job! \(firstWords[0]) is a first person word, and using \(secondWords[0]) implies a connection!", formattedText: highlightedPhrase, status: .complete)
        default:
            var feedback: String = "Great Job! "
            let lastIndexOfFirst = firstWords.count - 1
            let andIndexOfFirst = firstWords.count - 2
            let lastIndexOfSecond = secondWords.count - 1
            let andIndexOfSecond = secondWords.count - 2
            
            for (index, current) in firstWords.enumerated() {
                feedback.append("\(current), ")
                if index == andIndexOfFirst { feedback.append("and ") } else if index == lastIndexOfFirst { feedback.append("are first person words, and using ") }
            }
            
            for (index, current) in secondWords.enumerated() {
                feedback.append("\(current), ")
                if index == andIndexOfSecond { feedback.append("and ") } else if index == lastIndexOfSecond { feedback.append("implies a connection!") }
            }
            
            return PhraseScore(feedback: feedback, formattedText: highlightedPhrase, status: .complete)
        }
    }

    private func scorePositive(phrase: PhraseInfo) -> PhraseScore {
        var words: [String] = []
        let highlightedPhrase: NSMutableAttributedString = NSMutableAttributedString()
        
        for (index, current) in phrase.phrase.components(separatedBy: " ").enumerated() {
            let attributes: [NSAttributedString.Key : Any]
            if positiveWords.contains(where: { $0.word.lowercased() == current.lowercased() }) {
                words.append(current)
                attributes = [
                    .foregroundColor : UIColor.black,
                    .backgroundColor : #colorLiteral(red: 0, green: 0.7043033838, blue: 0.4950237274, alpha: 1)
                ]
            } else {
                attributes = [.foregroundColor : UIColor.black]
            }
            
            let currentWord = NSAttributedString(string: current, attributes: attributes)
            highlightedPhrase.append(currentWord)
            if index < (phrase.phrase.count - 1) { highlightedPhrase.append(NSAttributedString(string: " ")) }
        }
        
        switch words.count {
        case 0:
            return PhraseScore(feedback: "We're sorry, we were unable to detect any positive words. Try again.\n(Examples: love, hope, excited)", formattedText: highlightedPhrase, status: .incomplete)
        case 1:
            return PhraseScore(feedback: "Great Job! \(words[0]) signals positivity!", formattedText: highlightedPhrase, status: .complete)
        default:
            var feedback: String = "Great Job! "
            let lastIndex = words.count - 1
            let andIndex = words.count - 2
            
            for (index, current) in words.enumerated() {
                feedback.append("\(current), ")
                if index == andIndex { feedback.append("and ") } else if index == lastIndex { feedback.append("signals positivity!") }
            }
            
            return PhraseScore(feedback: feedback, formattedText: highlightedPhrase, status: .complete)
        }
    }

    private func scoreNegative(phrase: PhraseInfo) -> PhraseScore {
        var words: [String] = []
        let highlightedPhrase: NSMutableAttributedString = NSMutableAttributedString()
        
        for (index, current) in phrase.phrase.components(separatedBy: " ").enumerated() {
            let attributes: [NSAttributedString.Key : Any]
            if negativeWords.contains(where: { $0.word.lowercased() == current.lowercased() }) {
                words.append(current)
                attributes = [
                    .foregroundColor : UIColor.black,
                    .backgroundColor : #colorLiteral(red: 0.8509803922, green: 0.3490196078, blue: 0.3490196078, alpha: 1)
                ]
            } else {
                attributes = [.foregroundColor : UIColor.black]
            }
            
            let currentWord = NSAttributedString(string: current, attributes: attributes)
            highlightedPhrase.append(currentWord)
            if index < (phrase.phrase.count - 1) { highlightedPhrase.append(NSAttributedString(string: " ")) }
        }
        
        switch words.count {
        case 0:
            return PhraseScore(feedback: "We're sorry, we were unable to detect any negative words. Try again.\n(Examples: bad, terrible, sad)", formattedText: highlightedPhrase, status: .incomplete)
        case 1:
            return PhraseScore(feedback: "Great Job! \(words[0]) is a negative word. Learning to identify negative words will help you balance your speech by not coming across as too positive, or too negative.", formattedText: highlightedPhrase, status: .complete)
        default:
            var feedback: String = "Great Job! "
            let lastIndex = words.count - 1
            let andIndex = words.count - 2
            
            for (index, current) in words.enumerated() {
                feedback.append("\(current), ")
                if index == andIndex { feedback.append("and ") } else if index == lastIndex { feedback.append("are negative words. Learning to identify negative words will help you balance your speech by not coming across as too positive, or too negative.") }
            }
            
            return PhraseScore(feedback: feedback, formattedText: highlightedPhrase, status: .complete)
        }

    }
    
    func add(experience: Int) {
        level.add(experience: experience)
    }
    
}
