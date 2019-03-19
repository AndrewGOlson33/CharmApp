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
    var snapshots: [Snapshot] = []
    
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
    var backAndForth: [BackAndForth]
    var connection: [PersonalPronouns]
    var graphTone: [Sentiment]
    var tableViewTone: [Sentiment]
    var transcript: [Transcript]
    
    // coding keys
    
    enum CodingKeys: String, CodingKey {
        case topLevelMetrics = "topLevelMetrics"
        case backAndForth = "BackandForth"
        case connection = "PersonalPronouns"
        case graphTone = "sentimentAll"
        case tableViewTone = "sentimentRaw"
        case transcript = "Transcript"
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
    
}

// MARK: - Top Level Data

struct TopLevelMetric: Codable {
    
    var metric: String
    var rank: Double
    var raw: Double
    
    // coding keys to how data is stored on firebase
    enum CodingKeys: String, CodingKey {
        case metric = "Metric"
        case rank = "Rank"
        case raw = "Raw"
    }
}

// MARK: - Word Choice Data

struct WordChoice: Codable {
    // TODO: - Finish after data errors are corrected
    
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
    var startTime: Double
    var word: String
    
    enum CodingKeys: String, CodingKey {
        case adjustedAverage = "AdjustAvg1"
        case pronoun = "Pronoun"
        case shift = "Shift"
        case startTime = "startTime"
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
    var person: String
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
    var scoreString: String {
        return "\(score)"
    }
    
    init(title: String, score: Double) {
        self.title = title
        self.score = score
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
