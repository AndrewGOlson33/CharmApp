//
//  SubscriptionsViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 4/19/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit
import StoreKit

class SubscriptionsViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var outterView: UIView!
    @IBOutlet weak var viewActivity: UIActivityIndicatorView!
    
    // MARK: - Properties
    
    var tryingRestore: Bool = false
    var restoreFromButton: Bool = false
    
    // MARK: - Class Lifecycle Functions

    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup outter view
        outterView.layer.cornerRadius = 20
        outterView.layer.shadowColor = UIColor.black.cgColor
        outterView.layer.shadowRadius = 2.0
        outterView.layer.shadowOffset = CGSize(width: 2, height: 2)
        outterView.layer.shadowOpacity = 0.5
    }
    
    // MARK: - Button Handling
    
    @IBAction func restorePurchasesTapped(_ sender: Any) {
        tryingRestore = true
        restoreFromButton = true
        
        viewActivity.startAnimating()
        view.isUserInteractionEnabled = false
        
        // setup purchase notifications
        
        NotificationCenter.default.addObserver(self, selector: #selector(purchaseFailed(_:)), name: SubscriptionService.userCancelledNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(purchaseComplete), name: SubscriptionService.restoreSuccessfulNotification, object: nil)
        
        SubscriptionService.shared.restorePurchases()
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Subscription Notification Handling
    
    private func notificationReceived() {
        NotificationCenter.default.removeObserver(self, name: SubscriptionService.userCancelledNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: SubscriptionService.purchaseSuccessfulNotification, object: nil)
        
        DispatchQueue.main.async {
            self.viewActivity.stopAnimating()
            self.view.isUserInteractionEnabled = true
        }
    }
    
    private func createAlert(withTitle title: String, andMessage message: String, andDoneButton done: String, purchased: Bool = false) {
        DispatchQueue.main.async {
            self.notificationReceived()
            let successAlert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            successAlert.addAction(UIAlertAction(title: done, style: .default, handler: { _ in
                if purchased {
                    AppStatus.shared.validLicense = true
                    print("~>Setting valid license to true.")
                    UserDefaults.standard.set(true, forKey: Defaults.validLicense)
                    
                    // Add credits
                    if CharmUser.shared.userProfile.renewDate < Date() {
                        let status = SubscriptionService.shared.updateCredits()
                        print("~>Attempted to update credits and got status: \(status)")
                    }
                    
                    self.dismiss(animated: true, completion: nil)
                }
            }))
            self.present(successAlert, animated: true, completion: nil)
        }
        
    }
    
    @objc private func purchaseComplete() {
        notificationReceived()
        
        // a new subscription so add credits and set renew date to today
        if !tryingRestore {
            let date = Date(timeInterval: -1800, since: Date())
            CharmUser.shared.userProfile.renewDate = date
        }
        createAlert(withTitle: tryingRestore ? "Restore Complete" : "Purchase Complete", andMessage: tryingRestore ? "Your purchase has been restored." : "Congratulations on your purchase!  You may cancel anytime through iTunes.", andDoneButton: "Great!", purchased: true)
    }
    
    @objc private func purchaseFailed(_ sender: Notification) {
        notificationReceived()
        guard let error = sender.object as? SKError else {
            if restoreFromButton {
                restoreFromButton = false
                tryingRestore = false
                createAlert(withTitle: "Restore Failed", andMessage: "Could not find any purchases to restore.  Check your subscriptions in iTunes.", andDoneButton: "OK")
            } else {
                tryingRestore = false
                createAlert(withTitle: "Purchase Failed", andMessage: "Unable to make purchse.", andDoneButton: "OK")
            }
            return
        }
        
        switch error.code {
        case .cloudServiceNetworkConnectionFailed:
            createAlert(withTitle: "Connection Error", andMessage: "Unable to connect to iTunes. Check your connection and try again.", andDoneButton: "OK")
        case .paymentNotAllowed:
            createAlert(withTitle: "Payment Error", andMessage: "You are not authorised to make purchases, check with your Apple Family manager.", andDoneButton: "OK")
        case .paymentInvalid:
            createAlert(withTitle: "Payment Error", andMessage: "There is an error with you payment information, verify your payment information stored in iTunes.", andDoneButton: "OK")
        case .paymentCancelled:
            if !tryingRestore {
                tryingRestore = true
                SubscriptionService.shared.restorePurchases()
            } else if restoreFromButton {
                restoreFromButton = false
                tryingRestore = false
                createAlert(withTitle: "Restore Failed", andMessage: "Could not find any purchases to restore.  Check your subscriptions in iTunes.", andDoneButton: "OK")
            } else {
                tryingRestore = false
                createAlert(withTitle: "Purchase Failed", andMessage: "Unable to make purchse.", andDoneButton: "OK")
            }
            
            return
        default:
            createAlert(withTitle: "Unknown Error", andMessage: "An unknown error has occured, please check that you are logged into the iTunes store and that you have an internet connection.", andDoneButton: "OK")
        }
        
    }
    
}

// MARK: - Table View Functions

extension SubscriptionsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SubscriptionService.shared.options?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellID.SubscriptionsList, for: indexPath)
        
        guard let option = SubscriptionService.shared.options?[indexPath.row] else {
            print("~>No data")
            return cell
        }
        
        cell.textLabel?.text = option.product.localizedTitle
        cell.detailTextLabel?.text = option.formattedPrice
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard SubscriptionService.shared.options?.count ?? -1 >= indexPath.row, let subscription = SubscriptionService.shared.options?[indexPath.row] else {
            let alert = UIAlertController(title: "Unable to Complete Purchase", message: "Check that you have a valid internet connection, and try again.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        
        viewActivity.startAnimating()
        view.isUserInteractionEnabled = false
        
        // setup purchase notifications
        
        NotificationCenter.default.addObserver(self, selector: #selector(purchaseFailed(_:)), name: SubscriptionService.userCancelledNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(purchaseComplete), name: SubscriptionService.purchaseSuccessfulNotification, object: nil)
        
        SubscriptionService.shared.purchase(subscription: subscription)
    }

}
