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
    
    // Get raw value for summary values
    func getTopLevelRawValue(forSummaryItem item: SummaryItem) -> Double? {
        guard let summaryItem = topLevelMetrics.first(where: { (metric) -> Bool in
            return metric.metric == item.rawValue
        }) else { return nil }
        return summaryItem.raw
    }
    
}

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
