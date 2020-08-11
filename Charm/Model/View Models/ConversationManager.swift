//
//  CreatingConversationViewModel.swift
//  Charm
//
//  Created by Daniel Pratt on 2/3/20.
//  Copyright © 2020 Charm, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol LevelUpDelegate: class {
    func updated(progress: Double)
    func updated(level: Int, detail: String, progress: Double)
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

class ConversationManager: NSObject {
    
    static let shared = ConversationManager()
    
    // Model Objects
    var phrases: ConversationPhrases? {
        return FirebaseModel.shared.trainingModel?.conversationPhrases
    }
    
    var level: Int? {
        return FirebaseModel.shared.charmUser.trainingData.conversationLevel.currentLevel
    }
    
    var levelDetail: String? {
        return FirebaseModel.shared.charmUser.trainingData.conversationLevel.levelDetail
    }
    
    // Important Model Variables
    var loadStatus: LoadStatus = .loading
    
    var currentLevel: Int {
        didSet {
            delegate?.updated(level: currentLevel,
                              detail: FirebaseModel.shared.charmUser.trainingData.conversationLevel.levelDetail,
                              progress: progress)
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
    weak var delegate: LevelUpDelegate?
    
    // Available Phrases
    
    fileprivate var specific: [ConversationPhrase] = []
    fileprivate var connection: [ConversationPhrase] = []
    fileprivate var positive: [ConversationPhrase] = []
    fileprivate var negative: [ConversationPhrase] = []
    
    // Model for scoring
    fileprivate var concreteWords: [NounWord] {
        return FirebaseModel.shared.trainingModel?.concreteNouns ?? []
    }
    fileprivate var firstPersonWords: [String] {
        return FirebaseModel.shared.trainingModel?.firstPerson ?? []
    }
    fileprivate var secondPersonWords: [String] {
        return FirebaseModel.shared.trainingModel?.secondPerson ?? []
    }
    fileprivate var positiveWords: [ScoredWord] {
        return FirebaseModel.shared.trainingModel?.positiveWords ?? []
    }
    fileprivate var negativeWords: [ScoredWord] {
        return FirebaseModel.shared.trainingModel?.negativeWords ?? []
    }
    
    override init() {
        currentLevel = FirebaseModel.shared.charmUser.trainingData.conversationLevel.currentLevel
        progress = FirebaseModel.shared.charmUser.trainingData.conversationLevel.progress
        
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(dataDidLoaded), name: FirebaseNotification.trainingModelLoaded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(dataDidFailedToLoad), name: FirebaseNotification.trainingModelFailedToLoad, object: nil)
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func dataDidLoaded() {
        loadStatus = .loaded
    //   loadPhrases()
    }
    
    @objc private func dataDidFailedToLoad() {
        loadStatus = .failed
    }
    
    // MARK: - Setup Functions
    
    public func loadPhrases() {
        loadSpecific()
        loadConnection()
        loadPositive()
        loadNegative()
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
            phrase = specific.remove(at: Int.random(in: 0..<specific.count)).phrase
        case .connection:
            if connection.count < 1 { loadConnection() }
            phrase = connection.remove(at: Int.random(in: 0..<connection.count)).phrase
        case .positive:
            if positive.count < 1 { loadPositive() }
            // why is positive not working?
            phrase = positive.remove(at: Int.random(in: 0..<positive.count)).phrase
        case .negative:
            if negative.count < 1 { loadNegative() }
            phrase = negative.remove(at: Int.random(in: 0..<negative.count)).phrase
        }
        
        return PhraseInfo(phrase: phrase, type: type)
    }
    
    func getType(video type: PracticeVideo.PracticeVideoType) -> PhraseType {
        switch type {
        case .answer:
            return .specific
        case .question:
            if Bool.random() {
                return .connection
            } else {
                if Bool.random() {
                    return .negative
                } else {
                    return .positive
                }
            }
        }
    }
    
    // MARK: - Priavte Phrase Setup Methods
    
    fileprivate func getType() -> PhraseType {
        let random = Int.random(in: 1...100)
        switch random {
        case 1...10:
            // Reply with Something Negative (10%)
            return .negative
        case 11...35:
            // Reply with Something Positive (25%)
            return .positive
        case 36...65:
            // Reply Implying a Connection (30%)
            return .connection
        default:
            // Reply with Something Specific (35%)
            return .specific
        }
    }
    
    // MARK: Scoring Model
    
    func getScore(for phrase: PhraseInfo, isPrompt: Bool, completion: @escaping(_ score: PhraseScore) -> Void) {
        let score: PhraseScore
        switch phrase.type {
        case .specific:
            score = scoreSpecific(phrase: phrase, isPrompt: isPrompt)
        case .connection:
            score = scoreConnection(phrase: phrase, isPrompt: isPrompt)
        case .positive:
            score = scorePositive(phrase: phrase, isPrompt: isPrompt)
        case .negative:
            score = scoreNegative(phrase: phrase, isPrompt: isPrompt)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            guard let self = self else { return }
            completion(score)
            if self.currentLevel != FirebaseModel.shared.charmUser.trainingData.conversationLevel.currentLevel { self.currentLevel = FirebaseModel.shared.charmUser.trainingData.conversationLevel.currentLevel }
            self.progress = FirebaseModel.shared.charmUser.trainingData.conversationLevel.progress
        }
    }
    
    private func getRandomSuccessPrompt() -> String {
        let candidates: [String] = ["Great Job!", "Excellent!", "Perfecto!", "Amazing!"]
        return "\(candidates.choose(1)[0])\n"
    }
    
    private func scoreSpecific(phrase: PhraseInfo, isPrompt: Bool) -> PhraseScore {
        var words: [String] = []
        let highlightedPhrase: NSMutableAttributedString = NSMutableAttributedString()
        
        for (index, current) in phrase.phrase.components(separatedBy: " ").enumerated() {
            words.append(current)
            let attributes: [NSAttributedString.Key : Any]
            if concreteWords.contains(where: { $0.word.lowercased() == current.lowercased() }) {
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
        
        var randomConcreteWord = "dog"
        let concreteWords = FirebaseModel.shared.trainingModel?.concreteNouns ?? []
        if concreteWords.count > 1 {
            randomConcreteWord = "\(concreteWords.choose(1)[0].word)"
        }
        
        if isPrompt {
            switch words.count {
            case 0:
                return PhraseScore(feedback: "We were unable to detect a specific word. Saying specific things, such as \(randomConcreteWord), puts your ideas into other peoples minds.", formattedText: highlightedPhrase, status: .incomplete)
            case 1:
                if words.count < 5 {
                    return PhraseScore(feedback: "Saying a complete phrase (5 or more words) means you are adding enough to the conversation.", formattedText: highlightedPhrase, status: .incomplete)
                } else {
                    return PhraseScore(feedback: "\(getRandomSuccessPrompt())Saying specific things, such as \(randomConcreteWord), puts your ideas into other peoples minds", formattedText: highlightedPhrase, status: .complete)
                }

            default:
                return PhraseScore(feedback: "\(getRandomSuccessPrompt())Saying specific things, such as \(randomConcreteWord), puts your ideas into other peoples minds", formattedText: highlightedPhrase, status: .complete)
            }
        } else {
            if words.count < 5 {
                return PhraseScore(feedback: "Saying a complete phrase (5 or more words) means you are adding enough to the conversation.", formattedText: highlightedPhrase, status: .incomplete)
            } else {
                return PhraseScore(feedback: "\(getRandomSuccessPrompt())Saying specific things, such as \(randomConcreteWord), puts your ideas into other peoples minds", formattedText: highlightedPhrase, status: .complete)
            }
        }
    }
    
    private func scoreConnection(phrase: PhraseInfo, isPrompt: Bool) -> PhraseScore {
        var words: [String] = []
        var firstWords: [String] = []
        var secondWords: [String] = []
        let highlightedPhrase: NSMutableAttributedString = NSMutableAttributedString()
        
        for (index, current) in phrase.phrase.components(separatedBy: " ").enumerated() {
            words.append(current)
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
        
        var randomFirstPerson = "I"
        var randomSecondPerson = "You"
        let firstPersons = FirebaseModel.shared.trainingModel?.firstPerson ?? []
        if firstPersons.count > 1 {
            randomFirstPerson = "\(firstPersons.choose(1)[0])"
        }
        
        let secondPersons = FirebaseModel.shared.trainingModel?.secondPerson ?? []
        if secondPersons.count > 1 {
            randomSecondPerson = "\(secondPersons.choose(1)[0])"
        }
        
        if isPrompt {
            switch (firstWords.count, secondWords.count ) {
            case (0, 0), (0, 1):
                return PhraseScore(feedback: "We were unable to detect a first person pronoun. Saying first person pronouns, such as \(randomFirstPerson), focuses the conversation on yourself.", formattedText: highlightedPhrase, status: .incomplete)
            case (1, 0):
                return PhraseScore(feedback: "We were unable to detect a second person pronoun. Saying second person pronouns, such as \(randomSecondPerson), focuses the conversation on other people.", formattedText: highlightedPhrase, status: .incomplete)
            default:
                let random = Int(arc4random_uniform(2))
                if random == 0 {
                    return PhraseScore(feedback: "\(getRandomSuccessPrompt())Saying first person pronouns, such as \(randomFirstPerson), focuses the conversation on yourself", formattedText: highlightedPhrase, status: .complete)
                } else {
                    return PhraseScore(feedback: "\(getRandomSuccessPrompt())Saying second person pronouns, such as \(randomSecondPerson), focuses the conversation on other people", formattedText: highlightedPhrase, status: .complete)
                }
            }
        } else {
            if words.count < 5 {
                return PhraseScore(feedback: "Saying a complete phrase (5 or more words) means you are adding enough to the conversation.", formattedText: highlightedPhrase, status: .incomplete)
            } else {
                let random = Int(arc4random_uniform(2))
                if random == 0 {
                    return PhraseScore(feedback: "\(getRandomSuccessPrompt())Saying first person pronouns, such as \(randomFirstPerson), focuses the conversation on yourself", formattedText: highlightedPhrase, status: .complete)
                } else {
                    return PhraseScore(feedback: "\(getRandomSuccessPrompt())Saying second person pronouns, such as \(randomSecondPerson), focuses the conversation on other people", formattedText: highlightedPhrase, status: .complete)
                }
            }
        }
    }

    private func scorePositive(phrase: PhraseInfo, isPrompt: Bool) -> PhraseScore {
        var words: [String] = []
        let highlightedPhrase: NSMutableAttributedString = NSMutableAttributedString()
        
        for (index, current) in phrase.phrase.components(separatedBy: " ").enumerated() {
            words.append(current)
            let attributes: [NSAttributedString.Key : Any]
            if positiveWords.contains(where: { $0.word.lowercased() == current.lowercased() }) {
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
        
        var randomPositiveWord = "ability"
        let positiveWords = FirebaseModel.shared.trainingModel?.positiveWords ?? []
        if positiveWords.count > 1 {
            randomPositiveWord = "\(positiveWords.choose(1)[0].word)"
        }
        
        if isPrompt {
            switch words.count {
            case 0:
                return PhraseScore(feedback: "We were unable to detect a positive word. Saying positive things, such as \(randomPositiveWord), makes others feel happy.", formattedText: highlightedPhrase, status: .incomplete)
            default:
                if words.count < 5 {
                    return PhraseScore(feedback: "Saying a complete phrase (5 or more words) means you are adding enough to the conversation.", formattedText: highlightedPhrase, status: .incomplete)
                } else {
                    return PhraseScore(feedback: "\(getRandomSuccessPrompt())Saying positive things, such as \(randomPositiveWord), makes others feel happy", formattedText: highlightedPhrase, status: .complete)
                }
            }
        } else {
            if words.count < 5 {
                return PhraseScore(feedback: "Saying a complete phrase (5 or more words) means you are adding enough to the conversation.", formattedText: highlightedPhrase, status: .incomplete)
            } else {
                return PhraseScore(feedback: "\(getRandomSuccessPrompt())Saying positive things, such as \(randomPositiveWord), makes others feel happy", formattedText: highlightedPhrase, status: .complete)
            }
        }
    }

    private func scoreNegative(phrase: PhraseInfo, isPrompt: Bool) -> PhraseScore {
        var words: [String] = []
        let highlightedPhrase: NSMutableAttributedString = NSMutableAttributedString()
        
        for (index, current) in phrase.phrase.components(separatedBy: " ").enumerated() {
            words.append(current)
            let attributes: [NSAttributedString.Key : Any]
            if negativeWords.contains(where: { $0.word.lowercased() == current.lowercased() }) {
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
        
        var randomNegativeWord = "accuse"
        let negativeWords = FirebaseModel.shared.trainingModel?.negativeWords ?? []
        if negativeWords.count > 1 {
            randomNegativeWord = "\(negativeWords.choose(1)[0].word)"
        }
        
        if isPrompt {
            switch words.count {
            case 0:
                return PhraseScore(feedback: "We were unable to detect a negative word. Saying negative things, such as \(randomNegativeWord), makes others alert and focused.", formattedText: highlightedPhrase, status: .incomplete)

            default:
                if words.count < 5 {
                    return PhraseScore(feedback: "Saying a complete phrase (5 or more words) means you are adding enough to the conversation.", formattedText: highlightedPhrase, status: .incomplete)
                } else {
                    return PhraseScore(feedback: "\(getRandomSuccessPrompt())Saying negative things, such as \(randomNegativeWord), makes others alert and focused", formattedText: highlightedPhrase, status: .complete)
                }
            }
        } else {
            if words.count < 5 {
                return PhraseScore(feedback: "Saying a complete phrase (5 or more words) means you are adding enough to the conversation.", formattedText: highlightedPhrase, status: .incomplete)
            } else {
                return PhraseScore(feedback: "\(getRandomSuccessPrompt())Saying negative things, such as \(randomNegativeWord), makes others alert and focused", formattedText: highlightedPhrase, status: .complete)
            }
        }
    }
    
    func add(experience: Int) {
        FirebaseModel.shared.charmUser.trainingData.conversationLevel.add(experience: experience)
    }
}
