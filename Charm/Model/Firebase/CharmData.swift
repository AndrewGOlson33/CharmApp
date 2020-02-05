//
//  CharmData.swift
//  Charm
//
//  Created by Daniel Pratt on 3/18/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import Foundation
import Firebase

struct SnapshotsLoading {
    var isLoading: Bool = false
    
    static var shared = SnapshotsLoading()
}

struct Snapshot: FirebaseItem, Codable {
    var id: String?
    var ref: DatabaseReference?
    
    var date: Date? {
        guard let string = dateString else {
            return nil
        }
        
        let dFormatter = DateFormatter()
        dFormatter.dateFormat = "yyyyMMddHHmm"
        dFormatter.timeZone = TimeZone(identifier: "GMT")
        return dFormatter.date(from: string)
    }
    
    var dateString: String?
    var topLevelMetrics: [TopLevelMetric]
    var ideaEngagement: [IdeaEngagement]
    var conversation: [Conversation]
    var connection: [PersonalPronouns]
    var graphTone: [Sentiment]
    var tableViewTone: [Sentiment]
    var friends: [[String:String]]?
    var transcript: [Transcript]?
    var master: [Master]? {
        didSet {
            master?.sort { $0.index < $1.index }
        }
    }
    
    var friendlyDateString: String {
        guard let date = date else { return "" }
        
        let dFormatter = DateFormatter()
        dFormatter.dateStyle = .medium
        dFormatter.timeStyle = .short
        
        return dFormatter.string(from: date)
    }
    
    var friend: String {
        guard let friends = friends, let friend = friends.first(where: { (friend) -> Bool in
            friend.keys.contains("person")
        }) else { return "Unknown User" }
        if let name = friend["person"] { return name }
        return "Unknown User"
    }
    
    // coding keys
    
    enum CodingKeys: String, CodingKey {
        case topLevelMetrics = "topLevelMetrics"
        case ideaEngagement = "Concrete"
        case conversation = "BackandForth"
        case connection = "Connection"  // used to be PersonalPronouns
        case graphTone = "Sentiment" // used to be sentimentAll
        case tableViewTone = "Sentiment_Raw" // used to be sentimentRaw
        case friends = "friendsName"
        case transcript = "Transcript"
        case master = "Master"
    }
    
    init(snapshot: DataSnapshot) throws {
        guard snapshot.exists() else { throw FirebaseItemError.noSnapshot }
        id = snapshot.key
        ref = snapshot.ref
        dateString = id
        
        // start with empty values
        topLevelMetrics = []
        ideaEngagement = []
        conversation = []
        connection = []
        graphTone = []
        tableViewTone = []
        friends = [[:]]
        master = []
        
        // top level metrics
        let topLevelSnap = snapshot.childSnapshot(forPath: CodingKeys.topLevelMetrics.rawValue)
        for child in topLevelSnap.children {
            guard let snapshot = child as? DataSnapshot else { continue }
            topLevelMetrics.append(try TopLevelMetric(snapshot: snapshot))
        }
        
        // idea engagement (concrete)
        let concreteSnap = snapshot.childSnapshot(forPath: CodingKeys.ideaEngagement.rawValue)
        for child in concreteSnap.children {
            guard let snapshot = child as? DataSnapshot else { continue }
            ideaEngagement.append(try IdeaEngagement(snapshot: snapshot))
        }
        
        // conversation (back and forth)
        let convoSnap = snapshot.childSnapshot(forPath: CodingKeys.conversation.rawValue)
        for child in convoSnap.children {
            guard let snapshot = child as? DataSnapshot else { continue }
            conversation.append(try Conversation(snapshot: snapshot))
        }
        
        // connection (personal pronouns)
        let connectionSnap = snapshot.childSnapshot(forPath: CodingKeys.connection.rawValue)
        for child in connectionSnap.children {
            guard let snapshot = child as? DataSnapshot else { continue }
            connection.append(try PersonalPronouns(snapshot: snapshot))
        }
        
        // graphTone (Sentiment)
        let sentSnap = snapshot.childSnapshot(forPath: CodingKeys.graphTone.rawValue)
        for child in sentSnap.children {
            guard let snapshot = child as? DataSnapshot else { continue }
            graphTone.append(try Sentiment(snapshot: snapshot))
        }
        
        // table view tone (Sentiment Raw)
        let toneSnap = snapshot.childSnapshot(forPath: CodingKeys.tableViewTone.rawValue)
        for child in toneSnap.children {
            guard let snapshot = child as? DataSnapshot else { continue }
            tableViewTone.append(try Sentiment(snapshot: snapshot))
        }
        
        // friends (which is really just one friend)
        let friendsSnap = snapshot.childSnapshot(forPath: CodingKeys.friends.rawValue)
        for child in friendsSnap.children {
            guard let snapshot = child as? DataSnapshot, let friend = snapshot.value as? [String:String] else { continue }
            friends?.append(friend)
        }
        
        // Transcript
        let tranSnap = snapshot.childSnapshot(forPath: CodingKeys.transcript.rawValue)
        if tranSnap.exists() {
            transcript = []
            for child in tranSnap.children {
                guard let snapshot = child as? DataSnapshot else { continue }
                transcript?.append(try Transcript(snapshot: snapshot))
            }
        }
        
        // Master
        let masterSnap = snapshot.childSnapshot(forPath: CodingKeys.master.rawValue)
        if masterSnap.exists() {
            master = []
            for child in masterSnap.children {
                guard let snapshot = child as? DataSnapshot else { continue }
                master?.append(try Master(snapshot: snapshot))
            }
        }
        
    }
    
    // snapshots cannot be saved
    func toAny() -> [AnyHashable : Any] {
        return [:]
    }
    
    // snapshots cannot be saved
    func save() {
        return
    }
    
    // Snapshot Value Getters
    
    // Get raw value for summary values
    func getTopLevelRawValue(forSummaryItem item: SummaryItem) -> Double? {
        guard let summaryItem = topLevelMetrics.first(where: { (metric) -> Bool in
            return metric.metric == item.rawValue
        }) else { return nil }
        return summaryItem.raw
    }
    
    func getTopLevelRankValue(forSummaryItem item: SummaryItem) -> Double? {
        guard let summaryItem = topLevelMetrics.first(where: { (metric) -> Bool in
            return metric.metric == item.rawValue
        }) else { return nil }
        return summaryItem.rank
    }
    
    func getTopLevelScoreValue(forSummaryItem item: SummaryItem) -> Double? {
        guard let summaryItem = topLevelMetrics.first(where: { (metric) -> Bool in
            return metric.metric == item.rawValue
        }) else { return nil }
        return summaryItem.score
    }
    
    func getTopLevelFeedback(forSummaryItem item: SummaryItem) -> String? {
        guard let summaryItem = topLevelMetrics.first(where: { (metric) -> Bool in
            return metric.metric == item.rawValue
        }) else { return nil }
        
        return summaryItem.feedback
    }
    
}

// MARK: - Top Level Data

struct TopLevelMetric: FirebaseItem, Codable {
    var id: String?
    var ref: DatabaseReference?
    var metric: String
    var rank: Double
    var raw: Double
    var feedback: String?
    var score: Double?
    
    // coding keys to how data is stored on firebase
    enum CodingKeys: String, CodingKey {
        case metric = "Metric"
        case rank = "Rank"
        case raw = "Raw"
        case score = "Score"
        case feedback = "Feedback"
    }
    
    init(snapshot: DataSnapshot) throws {
        guard snapshot.exists() else { throw FirebaseItemError.noSnapshot }
        guard let values = snapshot.value as? [String:Any] else { throw FirebaseItemError.invalidData }
        id = snapshot.key
        ref = snapshot.ref
        
        metric = values[CodingKeys.metric.rawValue] as? String ?? ""
        feedback = values[CodingKeys.feedback.rawValue] as? String ?? ""
        rank = values[CodingKeys.rank.rawValue] as? Double ?? 0.0
        raw = values[CodingKeys.raw.rawValue] as? Double ?? 0.0
        score = values[CodingKeys.score.rawValue] as? Double ?? 0.0
    }
    
    func toAny() -> [AnyHashable : Any] {
        return [:]
    }
    
    func save() {
        return
    }
}

// MARK: - Word Choice Data

struct IdeaEngagement: FirebaseItem, Codable {
    
    var id: String?
    var ref: DatabaseReference?
    var score: Double
    var word: String
    private var concrete: Int
    
    var isConcrete: Bool {
        return concrete == 1 ? true : false
    }
    
    // coding keys to how data is stored on firebase
    enum CodingKeys: String, CodingKey {
        case score = "ema3"  // used to be score
        case word = "token"
        case concrete = "concrete"
    }
    
    init(snapshot: DataSnapshot) throws {
        guard snapshot.exists() else { throw FirebaseItemError.noSnapshot }
        guard let values = snapshot.value as? [String:Any] else { throw FirebaseItemError.invalidData }
        id = snapshot.key
        ref = snapshot.ref
        
        score = values[CodingKeys.score.rawValue] as? Double ?? 0.0
        word = values[CodingKeys.word.rawValue] as? String ?? ""
        concrete = values[CodingKeys.concrete.rawValue] as? Int ?? 0
    }
    
    func toAny() -> [AnyHashable : Any] {
        return [:]
    }
    
    func save() {
        return
    }
}

// MARK: - Extension to get bool value from int

extension Int {
    var boolValue: Bool { return self != 0 }
}

// MARK: - Back and Forth

struct Conversation: FirebaseItem, Codable {
    var id: String?
    var ref: DatabaseReference?
    var adjustedAvg: Double?
    var person: String
    var word: String
    
    enum CodingKeys: String, CodingKey {
        case adjustedAvg = "AdjustAvg1"
        case person = "Person"
        case word = "word"
    }
    
    init(snapshot: DataSnapshot) throws {
        guard snapshot.exists() else { throw FirebaseItemError.noSnapshot }
        guard let values = snapshot.value as? [String:Any] else { throw FirebaseItemError.invalidData }
        id = snapshot.key
        ref = snapshot.ref
        
        adjustedAvg = values[CodingKeys.adjustedAvg.rawValue] as? Double
        person = values[CodingKeys.person.rawValue] as? String ?? ""
        word = values[CodingKeys.word.rawValue] as? String ?? ""
    }
    
    func toAny() -> [AnyHashable : Any] {
        return [:]
    }
    
    func save() {
        return
    }
    
}

// MARK: - Personal Pronouns (Connection)

struct PersonalPronouns: FirebaseItem, Codable {
    var id: String?
    var ref: DatabaseReference?
    var adjustedAverage: Double?
    var classification: Int
    var shift: Int?
    var word: String
    
    enum CodingKeys: String, CodingKey {
        case adjustedAverage = "AdjustAvg1"
        case classification = "Classification"
        case shift = "higlight"
        case word = "word"
    }
    
    init(snapshot: DataSnapshot) throws {
        guard snapshot.exists() else { throw FirebaseItemError.noSnapshot }
        guard let values = snapshot.value as? [String:Any] else { throw FirebaseItemError.invalidData }
        id = snapshot.key
        ref = snapshot.ref
        
        adjustedAverage = values[CodingKeys.adjustedAverage.rawValue] as? Double
        classification = values[CodingKeys.classification.rawValue] as? Int ?? 1
        shift = values[CodingKeys.shift.rawValue] as? Int
        word = values[CodingKeys.word.rawValue] as? String ?? ""
    }
    
    func toAny() -> [AnyHashable : Any] {
        return [:]
    }
    
    func save() {
        return
    }
}

// MARK: - Sentiment (Tone)

struct Sentiment: FirebaseItem, Codable {
    var id: String?
    var ref: DatabaseReference?
    var roll3: Double
    var rollNeg3: Double
    var rollPos3: Double
    var score: Int
    var word: String
    
    enum CodingKeys: String, CodingKey {
        case roll3 = "Roll3"
        case rollNeg3 = "RollNeg3"
        case rollPos3 = "RollPos3"
        case score = "score"
        case word = "word"
    }
    
    init(snapshot: DataSnapshot) throws {
        guard snapshot.exists() else { throw FirebaseItemError.noSnapshot }
        guard let values = snapshot.value as? [String:Any] else { throw FirebaseItemError.invalidData }
        id = snapshot.key
        ref = snapshot.ref
        
        roll3 = values[CodingKeys.roll3.rawValue] as? Double ?? 0.0
        rollNeg3 = values[CodingKeys.rollNeg3.rawValue] as? Double ?? 0.0
        rollPos3 = values[CodingKeys.rollPos3.rawValue] as? Double ?? 0.0
        score = values[CodingKeys.score.rawValue] as? Int ?? 1
        word = values[CodingKeys.word.rawValue] as? String ?? ""
    }
    
    func toAny() -> [AnyHashable : Any] {
        return [:]
    }
    
    func save() {
        return
    }
}

// MARK: - Transcript

struct Transcript: FirebaseItem, Codable {
    var id: String?
    var ref: DatabaseReference?
    var person: String
    var phrase: Int
    var words: String
    
    enum CodingKeys: String, CodingKey {
        case person = "Person"
        case phrase = "Phrase"
        case words = "Words"
    }
    
    init(snapshot: DataSnapshot) throws {
        guard snapshot.exists() else { throw FirebaseItemError.noSnapshot }
        guard let values = snapshot.value as? [String:Any] else { throw FirebaseItemError.invalidData }
        id = snapshot.key
        ref = snapshot.ref
        
        person = values[CodingKeys.person.rawValue] as? String ?? ""
        phrase = values[CodingKeys.phrase.rawValue] as? Int ?? Int(snapshot.key) ?? 0
        words = values[CodingKeys.words.rawValue] as? String ?? ""
    }
    
    func toAny() -> [AnyHashable : Any] {
        return [:]
    }
    
    func save() {
        return
    }
}

// MARK: - Transcript Master

struct Master: FirebaseItem, Codable {
    var id: String?
    var ref: DatabaseReference?
    
    var index: Int
    var person: String
    var userId: String
    var abstract: Bool
    var concrete: Bool
    var firstPerson: Bool
    var secondPerson: Bool
    var plural: Bool
    var positiveWord: Bool
    var negativeWord: Bool
    var word: String
    
    enum CodingKeys: String, CodingKey {
        case index = "index"
        case person = "Person"
        case userId = "UserID"
        case abstract = "abstract"
        case concrete = "concrete"
        case firstPerson = "first"
        case secondPerson = "second"
        case plural = "plural"
        case positiveWord = "positive"
        case negativeWord = "negative"
        case word = "word"
    }
    
    init(snapshot: DataSnapshot) throws {
        guard snapshot.exists() else { throw FirebaseItemError.noSnapshot }
        guard let values = snapshot.value as? [String:Any] else { throw FirebaseItemError.invalidData }
        id = snapshot.key
        ref = snapshot.ref
        
        index = values[CodingKeys.index.rawValue] as? Int ?? -1
        person = values[CodingKeys.person.rawValue] as? String ?? ""
        userId = values[CodingKeys.userId.rawValue] as? String ?? ""
        abstract = values[CodingKeys.abstract.rawValue] as? Bool ?? false
        concrete = values[CodingKeys.concrete.rawValue] as? Bool ?? false
        firstPerson = values[CodingKeys.firstPerson.rawValue] as? Bool ?? false
        secondPerson = values[CodingKeys.secondPerson.rawValue] as? Bool ?? false
        plural = values[CodingKeys.plural.rawValue] as? Bool ?? false
        positiveWord = values[CodingKeys.positiveWord.rawValue] as? Bool ?? false
        negativeWord = values[CodingKeys.negativeWord.rawValue] as? Bool ?? false
        word = values[CodingKeys.word.rawValue] as? String ?? ""
    }
    
    func toAny() -> [AnyHashable : Any] {
        return [:]
    }
    
    func save() {
        return
    }
}

// MARK: - Structs for creating table view cells from

struct SummaryCellInfo {
    var title: String
    var score: Double
    var percent: Double
    var scalebarType: SliderType
    
    private var formatter = NumberFormatter()
    
    var summaryTitle: String {
        return title + ":"
    }
    
    var detailedTitle: String {
        return title + ": \(Int(score))"
    }
    var detailedScore: String {
        return "\(Int(score))/10"
    }
    
    var scoreString: String {
        return "\(Int(score * 100.0))%"
    }
    
    var percentString: String {
        let percentScore = score * 100
        let percentValue = Double(round(percentScore * 100) / 100)
        guard let value = formatter.string(from: NSNumber(value: percentValue)) else { return "0%" }
        return "\(value)%"
    }
    
    init(title: String, score: Double, percent: Double, barType: SliderType = .standard) {
        self.title = title
        self.score = score
        self.percent = percent
        self.scalebarType = barType
        
        formatter.maximumSignificantDigits = 3
    }
    
}

struct SliderCellTitle {
    var description: String
    var hint: String
}

struct SliderCellInfo {
    var details: SliderDetails
    var title: SliderCellTitle
    var score: Double
    var position: CGFloat
    let backgroundImage: UIImage
    
    private var formatter = NumberFormatter()
    
    var percentString: String {
        let percentScore = score * 100
        let percentValue = Double(round(percentScore * 100) / 100)
        guard let value = formatter.string(from: NSNumber(value: percentValue)) else { return "0%" }
        return "\(value)%"
    }
    
    var positionPercent: String {
        if position == 1.0 { return "100%" }
        let value = Int(round(position * 100.0))
        return "\(value)%"
    }
    
    init(details: SliderDetails, title: SliderCellTitle, score: Double, position: CGFloat, backgroundImage: UIImage) {
        self.details = details
        self.title = title
        self.score = score
        self.position = position
        self.backgroundImage = backgroundImage
        
        formatter.maximumSignificantDigits = 3
    }
}

enum ValueType {
    case int, double, percent
}

struct SliderDetails {
    var type: SliderType
    var valueType: ValueType
    var startValue: CGFloat
    var endValue: CGFloat
    var color: UIColor
    
    init(type: SliderType, valueType: ValueType = .int, start: CGFloat = 0, end: CGFloat = 0, color: UIColor) {
        self.type = type
        self.valueType = valueType
        startValue = start
        endValue = end
        self.color = color
    }
}

struct TranscriptCellInfo {
    
    var text: NSMutableAttributedString
    var position: Int?
    var isUser: Bool
    
    init(withText text: NSMutableAttributedString, isUser: Bool) {
        self.text = text
        self.isUser = isUser
    }
    
    init(withText text: NSMutableAttributedString, at position: Int, isUser: Bool) {
        self.text = text
        self.position = position
        self.isUser = isUser
    }
    
}

// MARK: - Callout Data

struct CalloutInfo {
    var value: String
    var transcriptIndex: Int
}

// MARK: - String Extension to Count Words

// enumerateStrings
extension String {
    var numberOfWords: Int {
        return self.components(separatedBy: " ").count
    }
}
