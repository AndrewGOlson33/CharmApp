//
//  Session.swift
//  Charm
//
//  Created by Daniel Pratt on 4/19/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import Foundation

public struct Session {
    public let id: SessionId
    public var paidSubscriptions: [PaidSubscription]
    
    public var currentSubscription: PaidSubscription? {
        print("~>Start date: \(CharmService.shared.simulatedStartDate)")
        let sortedByMostRecentPurchase = paidSubscriptions.sorted { $0.purchaseDate > $1.purchaseDate }
        
        return sortedByMostRecentPurchase.first
    }
    
    public var receiptData: Data
    public var parsedReceipt: [String: Any]
    
    init(receiptData: Data, parsedReceipt: [String: Any]) {
        id = UUID().uuidString
        self.receiptData = receiptData
        self.parsedReceipt = parsedReceipt
        
        if let receipt = parsedReceipt["receipt"] as? [String: Any], let purchases = receipt["in_app"] as? Array<[String: Any]> {
            var subscriptions = [PaidSubscription]()
            for purchase in purchases {
                if let paidSubscription = PaidSubscription(json: purchase) {
                    subscriptions.append(paidSubscription)
                }
            }
            
            paidSubscriptions = subscriptions
        } else {
            paidSubscriptions = []
        }
    }
}

// MARK: - Equatable

extension Session: Equatable {
    public static func ==(lhs: Session, rhs: Session) -> Bool {
        return lhs.id == rhs.id
    }
}
