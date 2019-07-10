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
    var ideaEngagement: [IdeaEngagement]
    var conversation: [Conversation]
    var connection: [PersonalPronouns]
    var graphTone: [Sentiment]
    var tableViewTone: [Sentiment]
//    var transcript: [Transcript]
    
    // coding keys
    
    enum CodingKeys: String, CodingKey {
        case topLevelMetrics = "topLevelMetrics"
        case ideaEngagement = "Concrete"
        case conversation = "BackandForth"
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

struct IdeaEngagement: Codable {
    var score: Double
    var word: String
    private var concrete: Int
    
    var isConcrete: Bool {
        return concrete.boolValue
    }
    
    // coding keys to how data is stored on firebase
    enum CodingKeys: String, CodingKey {
        case score = "ema3"  // used to be score
        case word = "token"
        case concrete = "concrete"
    }
}

// MARK: - Extension to get bool value from int

extension Int {
    var boolValue: Bool { return self != 0 }
}

// MARK: - Back and Forth

struct Conversation: Codable {
    var adjustedAvg: Double?
    var person: String
    var word: String
    
    enum CodingKeys: String, CodingKey {
        case adjustedAvg = "AdjustAvg1"
        case person = "Person"
        case word = "word"
    }
    
}

// MARK: - Personal Pronouns (Connection)

struct PersonalPronouns: Codable {
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
    var scalebarType: BarType
    
    private var formatter = NumberFormatter()
    
    var detailedTitle: String {
        return title + ": \(Int(score))"
    }
    
    var scoreString: String {
        return "\(score)"
    }
    
    var percentString: String {
        let percentScore = score * 100
        let percentValue = Double(round(percentScore * 100) / 100)
        guard let value = formatter.string(from: NSNumber(value: percentValue)) else { return "0%" }
        return "\(value)%"
    }
    
    init(title: String, score: Double, percent: Double, barType: BarType = .Green) {
        self.title = title
        self.score = score
        self.percent = percent
        self.scalebarType = barType
        
        formatter.maximumSignificantDigits = 3
    }
    
}

struct SliderCellInfo {
    var details: SliderDetails
    var title: String
    var score: Double
    var position: CGFloat
    
    private var formatter = NumberFormatter()
    
    var percentString: String {
        let percentScore = score * 100
        let percentValue = Double(round(percentScore * 100) / 100)
        guard let value = formatter.string(from: NSNumber(value: percentValue)) else { return "0%" }
        return "\(value)%"
    }
    
    init(details: SliderDetails, title: String, score: Double, position: CGFloat) {
        self.details = details
        self.title = title
        self.score = score
        self.position = position
        
        formatter.maximumSignificantDigits = 3
    }
}

enum ValueType {
    case int, double, percent
}

struct SliderDetails {
    var type: SliderType
    var valueType: ValueType
    var minBlue: CGFloat
    var maxBlue: CGFloat
    var minRed: CGFloat?
    var maxRed: CGFloat?
    
    var hasRed: Bool {
        return minRed != nil && maxRed != nil
    }
    
    var minRedValue: CGFloat {
        if let value = minRed { return value }
        
        return -1
    }
    
    var maxRedValue: CGFloat {
        if let value = maxRed { return value }
        
        return -1
    }
    
    init(type: SliderType, valueType: ValueType = .int, minBlue: CGFloat = 0, maxBlue: CGFloat = 1, minRed: CGFloat? = nil, maxRed: CGFloat? = nil) {
        self.type = type
        self.valueType = valueType
        self.minBlue = minBlue
        self.maxBlue = maxBlue
        self.minRed = minRed
        self.maxRed = maxRed
    }
}

struct TranscriptCellInfo {
    
    var text: String
    
    init(withText text: String) {
        self.text = text
    }
    
}
