//
//  PaidSubscription.swift
//  Charm
//
//  Created by Daniel Pratt on 2/22/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import Foundation

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss VV"
    
    return formatter
}()

public struct PaidSubscription {
    
    public enum Level: String {
        case threeMonthly = "Three Credits Per Month"
        case fiveMonthly = "Five Credits Per Month"
        case none = "Not Subscribed"
        
        init(productId: String) {
            if productId.contains("threetokens.monthly") {
                self = .threeMonthly
            } else if productId.contains("fiveTokens.monthly") {
                self = .fiveMonthly
            } else {
                self = .none
            }
        }
    }
    
    public let productId: String
    public let purchaseDate: Date
    public let expiresDate: Date
    public let level: Level
    
    public var isActive: Bool {
        return Date() <= expiresDate
    }
    
    init?(json: [String: Any]) {
        guard
            let productId = json["product_id"] as? String,
            let purchaseDateString = json["purchase_date"] as? String,
            let purchaseDate = dateFormatter.date(from: purchaseDateString),
            let expiresDateString = json["expires_date"] as? String,
            let expiresDate = dateFormatter.date(from: expiresDateString)
            else {
                return nil
        }
        
        self.productId = productId
        self.purchaseDate = purchaseDate
        self.expiresDate = expiresDate
        self.level = Level(productId: productId)
    }
}
