//
//  CharmData.swift
//  Charm
//
//  Created by Daniel Pratt on 3/18/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import Foundation
import Firebase
import CodableFirebase

struct UserSnapshotData {
    var snapshots: [Snapshot] = [] {
        didSet {
            snapshots.sort { (lhs, rhs) -> Bool in
                lhs.date ?? Date.distantPast > rhs.date ?? Date.distantPast
            }
            
            NotificationCenter.default.post(name: FirebaseNotification.SnapshotLoaded, object: nil)
        }
    }
    var selectedSnapshot: Snapshot? = nil
    
    static var shared = UserSnapshotData()
}

struct Snapshot: Codable {
    
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
    var wordChoice: [WordChoice]
    var backAndForth: [BackAndForth]
    var connection: [PersonalPronouns]
    var graphTone: [Sentiment]
    var tableViewTone: [Sentiment]
//    var transcript: [Transcript]
    
    // coding keys
    
    enum CodingKeys: String, CodingKey {
        case topLevelMetrics = "topLevelMetrics"
        case wordChoice = "Concrete"
        case backAndForth = "BackandForth"
        case connection = "Connection"  // used to be PersonalPronouns
        case graphTone = "Sentiment" // used to be sentimentAll
        case tableViewTone = "Sentiment_Raw" // used to be sentimentRaw
//        case transcript = "Transcipt" // used to be Transcript
    }
    
    // Snapshot Value Getters
    
    // Get raw value for summary values
    func getTopLevelRawValue(forSummaryItem item: SummaryItem) -> Double? {
        guard let summaryItem = topLevelMetrics.first(where: { (metric) -> Bool in
            return metric.metric == item.rawValue
        }) else { return nil }
        return summaryItem.raw
    }
    
    func getTopLevelRawLevelValue(forSummaryItem item: SummaryItem) -> Double? {
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
    
}

// MARK: - Top Level Data

struct TopLevelMetric: Codable {
    
    var metric: String
    var rank: Double
    var raw: Double
    var score: Double?
    
    // coding keys to how data is stored on firebase
    enum CodingKeys: String, CodingKey {
        case metric = "Metric"
        case rank = "Rank"
        case raw = "Raw"
        case score = "Score"
    }
}

// MARK: - Word Choice Data

struct WordChoice: Codable {
    var score: Double
    var word: String
    
    // coding keys to how data is stored on firebase
    enum CodingKeys: String, CodingKey {
        case score = "score"  // used to be ema3
        case word = "token"
    }
}

// MARK: - Back and Forth

struct BackAndForth: Codable {
    var adjustedAvg: Double?
    var person: String
    var word: String
    
    enum CodingKeys: String, CodingKey {
        case adjustedAvg = "AdjustAvg"
        case person = "Person"
        case word = "word"
    }
    
}

// MARK: - Personal Pronouns (Connection)

struct PersonalPronouns: Codable {
    var adjustedAverage: Double?
    var pronoun: Int
    var shift: Int?
//    var startTime: Double
    var word: String
    
    enum CodingKeys: String, CodingKey {
        case adjustedAverage = "AdjustAvg1"
        case pronoun = "Pronoun"
        case shift = "higlight"
//        case startTime = "startTime"
        case word = "word"
    }
}

// MARK: - Sentiment (Tone)

struct Sentiment: Codable {
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
}

// MARK: - Transcript

struct Transcript: Codable {
    var person: String? = ""
    var words: String
    
    enum CodingKeys: String, CodingKey {
        case person = "Person"
        case words = "Words"
    }
}

// MARK: - Structs for creating table view cells from

struct SummaryCellInfo {
    var title: String
    var score: Double
    var percent: Double
    
    var scoreString: String {
        return "\(score)"
    }
    
    var percentString: String {
        return "\((percent * 100).rounded())%"
    }
    
    init(title: String, score: Double, percent: Double) {
        self.title = title
        self.score = score
        self.percent = percent
    }
    
}

struct ScalebarCellInfo {
    var type: BarType
    var title: String
    var score: Double
    var position: Double
    
    init(type: BarType, title: String, score: Double, position: Double) {
        self.type = type
        self.title = title
        self.score = score
        self.position = position
    }
}

struct TranscriptCellInfo {
    
    var text: String
    
    init(withText text: String) {
        self.text = text
    }
    
}
