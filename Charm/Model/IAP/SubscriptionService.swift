//
//  SubscriptionService.swift
//  Charm
//
//  Created by Daniel Pratt on 4/19/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import Foundation
import StoreKit
import Firebase
import CodableFirebase

enum CreditUpdateStatus {
    case noSubscription
    case addedCredits
    case noChanges
    case userNotLoaded
    case receiptsNotLoaded
}

class SubscriptionService: NSObject {
    static let CharmThreeCreditsMonthlySubscription = "com.charismaanalytics.Charm.sub.threetokens.monthly"
    static let CharmFiveCreditsMonthlySubscription = "com.charismaanalytics.Charm.sub.fiveTokens.monthly"
    static let sessionIdSetNotification = Notification.Name("SubscriptionServiceSessionIdSetNotification")
    static let optionsLoadedNotification = Notification.Name("SubscriptionServiceOptionsLoadedNotification")
    static let restoreSuccessfulNotification = Notification.Name("SubscriptionServiceRestoreSuccessfulNotification")
    static let purchaseSuccessfulNotification = Notification.Name("SubscriptionServiceRestoreSuccessfulNotification")
    static let userCancelledNotification = Notification.Name("SubscriptionServiceCancelledNotification")
    
    static let shared = SubscriptionService()
    
    var receiptsCurrent: Bool = false
    
    var hasReceiptData: Bool {
        return loadReceipt() != nil
    }
    
    var currentSessionId: String? {
        didSet {
            NotificationCenter.default.post(name: SubscriptionService.sessionIdSetNotification, object: currentSessionId)
        }
    }
    
    var currentSubscription: PaidSubscription?
    
    var options: [Subscription]? {
        didSet {
            NotificationCenter.default.post(name: SubscriptionService.optionsLoadedNotification, object: options)
        }
    }
    
    func updateCredits() -> CreditUpdateStatus {
        guard CharmUser.shared != nil else { return .userNotLoaded }
        guard hasReceiptData && receiptsCurrent else { return .receiptsNotLoaded }
        guard let subscription = currentSubscription, subscription.isActive else { return .noSubscription }
        
        if CharmUser.shared.userProfile.renewDate > Date() {
            print("~>Renew date is in the future: \(CharmUser.shared.userProfile.renewDateString)")
            return .noChanges
        } else {
            print("~>Should be adding credits")
            addCredits()
            return .addedCredits
        }
    }
    
    private func addCredits() {
        if CharmUser.shared.userProfile.renewDate > Date() {
            print("~>Save user profile to database.")
            saveUserProfileToFirebase()
            return
        }
        let numCredits = numberOfCredits()
        if numCredits == 0 {
            print("~>Returning with 0 credits.")
            return
        }
        CharmUser.shared.userProfile.numCredits += numCredits
        
        // add a month
        let aMonth = DateComponents(month: 1)
        guard let newDate = Calendar.current.date(byAdding: aMonth, to: CharmUser.shared.userProfile.renewDate) else { return }
        CharmUser.shared.userProfile.renewDate = newDate
        print("~>Charm user got a new date: \(CharmUser.shared.userProfile.renewDateString)")
        addCredits()
    }
    
    private func saveUserProfileToFirebase() {
        
        if CharmUser.shared.userProfile.membershipStatus != .currentSubscriber { CharmUser.shared.userProfile.membershipStatus = .currentSubscriber }
        
        let profile = CharmUser.shared.userProfile
        
        do {
            let data = try FirebaseEncoder().encode(profile)
            Database.database().reference().child(FirebaseStructure.Users).child(CharmUser.shared.id!).child(FirebaseStructure.CharmUser.Profile).setValue(data)
            print("~>Set user profile with new date")
        } catch let error {
            print("~>There was an error: \(error)")
        }
    }
    
    private func numberOfCredits() -> Int {
        guard let current = currentSubscription else { return 0 }
        switch current.level {
        case .threeMonthly:
            return 3
        case .fiveMonthly:
            return 5
        case .none:
            return 0
        }
    }
    
    func loadSubscriptionOptions() {
        print("~>Loading subscription options.")
        let threeMonthly = SubscriptionService.CharmThreeCreditsMonthlySubscription
        let fiveMonthly = SubscriptionService.CharmFiveCreditsMonthlySubscription
        
        let productIDs = Set([threeMonthly, fiveMonthly])
        
        let request = SKProductsRequest(productIdentifiers: productIDs)
        request.delegate = self
        request.start()
    }
    
    func purchase(subscription: Subscription) {
        let payment = SKPayment(product: subscription.product)
        SKPaymentQueue.default().add(payment)
    }
    
    func restorePurchases() {
        print("~>Trying to restore purchases.")
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    func uploadReceipt(completion: ((_ success: Bool) -> Void)? = nil) {
        if let receiptData = loadReceipt() {
            CharmService.shared.upload(receipt: receiptData) { [weak self] (result) in
                guard let strongSelf = self else { return }
                switch result {
                case .success(let result):
                    strongSelf.currentSessionId = result.sessionId
                    strongSelf.currentSubscription = result.currentSubscription
                    strongSelf.receiptsCurrent = true
                    print("~>Result: \(result) Current subscription: \(String(describing: result.currentSubscription))")
                    completion?(true)
                case .failure(let error):
                    print("🚫 Receipt Upload Failed: \(error)")
                    completion?(false)
                }
            }
        } else {
            receiptsCurrent = true
            print("~>There are no receipts.")
            completion?(false)
        }
    }
    
    private func loadReceipt() -> Data? {
        guard let url = Bundle.main.appStoreReceiptURL else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            return data
        } catch {
            print("Error loading receipt data: \(error.localizedDescription)")
            return nil
        }
    }
    
}

// MARK: - SKProductsRequestDelegate

extension SubscriptionService: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        print("~>Product request came back.")
        print("~>Response: \(response.products)")
        options = response.products.map { Subscription(product: $0) }
        print("~>Found options: \(String(describing: options))")
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        if request is SKProductsRequest {
            print("~>Product request failed.")
            print("Subscription Options Failed Loading: \(error.localizedDescription)")
        }
    }
    
    func requestDidFinish(_ request: SKRequest) {
        print("~>Product request did finish.")
    }
}
