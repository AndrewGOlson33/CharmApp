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

enum CreditUpdateStatus {
    case noSubscription
    case addedCredits
    case noChanges
    case userNotLoaded
    case receiptsNotLoaded
}

class SubscriptionService: NSObject {
    static let CharmThreeCreditsMonthlySubscription = SubscriptionID.standard
    static let CharmFiveCreditsMonthlySubscription = SubscriptionID.premium
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
        guard FirebaseModel.shared.charmUser != nil else { return .userNotLoaded }
        guard hasReceiptData && receiptsCurrent else { return .receiptsNotLoaded }
        guard let subscription = currentSubscription, subscription.isActive else { return .noSubscription }
        
        if FirebaseModel.shared.charmUser.userProfile.renewDate > Date() {
            print("~>Renew date is in the future: \(FirebaseModel.shared.charmUser.userProfile.renewDateString)")
            return .noChanges
        } else {
            print("~>Should be adding credits")
            addCredits()
            return .addedCredits
        }
    }
    
    private func addCredits() {
        if FirebaseModel.shared.charmUser.userProfile.renewDate > Date() {
            print("~>Save user profile to database.")
            saveUserProfileToFirebase()
            return
        }
        let numCredits = numberOfCredits()
        if numCredits == 0 {
            print("~>Returning with 0 credits.")
            return
        }
        FirebaseModel.shared.charmUser.userProfile.numCredits += numCredits
        
        // add a month
        let aMonth = DateComponents(month: 1)
        guard let newDate = Calendar.current.date(byAdding: aMonth, to: FirebaseModel.shared.charmUser.userProfile.renewDate) else { return }
        FirebaseModel.shared.charmUser.userProfile.renewDate = newDate
        print("~>Charm user got a new date: \(FirebaseModel.shared.charmUser.userProfile.renewDateString)")
        addCredits()
    }
    
    private func saveUserProfileToFirebase() {
        if FirebaseModel.shared.charmUser.userProfile.membershipStatus != .currentSubscriber { FirebaseModel.shared.charmUser.userProfile.membershipStatus = .currentSubscriber
        }
        
        let profile = FirebaseModel.shared.charmUser.userProfile
    Database.database().reference().child(FirebaseStructure.usersLocation).child(FirebaseModel.shared.charmUser.id!).child(FirebaseStructure.CharmUser.profileLocation).setValue(profile.toAny())
    }
    
    private func numberOfCredits() -> Int {
        guard let current = currentSubscription else { return 0 }
        switch current.level {
        case .Standard:
            return 3
        case .Premium:
            return 5
        case .none:
            return 0
        }
    }
    
    func loadSubscriptionOptions() {
        let standard = SubscriptionService.CharmThreeCreditsMonthlySubscription
        let premium = SubscriptionService.CharmFiveCreditsMonthlySubscription
        
        let productIDs = Set([standard, premium])
        
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
            print("~>Subscription Options Failed Loading: \(error.localizedDescription)")
        }
    }
    
    func requestDidFinish(_ request: SKRequest) {
        print("~>Product request did finish.")
    }
}
