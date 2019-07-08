//
//  SubscriptionsTableViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 7/3/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit
import StoreKit
import Firebase
import CodableFirebase

class SubscriptionsTableViewController: UITableViewController {
    
    // MARK: - Price Labels
    
    @IBOutlet weak var lblStandardPrice: UILabel!
    @IBOutlet weak var lblPremiumPrice: UILabel!
    
    // Cells For Setting Accessory
    @IBOutlet weak var cellFree: UITableViewCell!
    @IBOutlet weak var cellStandard: UITableViewCell!
    @IBOutlet weak var cellPremium: UITableViewCell!
    
    // MARK: - Properties
    
    var restoreFromButton: Bool = false
    var viewActivity: UIActivityIndicatorView? = nil
    var fromSettings: Bool = false
    var parentView: StartupSubscriptionsViewController? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // update prices in UI if necessary
        checkPrices()
        setCheckMark()
    }
    
    // MARK: - Private Helper Functions
    
    private func checkPrices() {
        guard let options = SubscriptionService.shared.options else {
            print("~>No data")
            return
        }
        
        for option in options {
            switch option.product.productIdentifier {
            case SubscriptionID.Standard:
                if lblStandardPrice.text != option.priceDetail { lblStandardPrice.text = option.priceDetail }
            case SubscriptionID.Premium:
                if lblPremiumPrice.text != option.priceDetail { lblPremiumPrice.text = option.priceDetail }
            default:
                print("~>Update app")
            }
        }
    }
    
    private func setCheckMark() {
        cellFree.accessoryType = .none
        cellStandard.accessoryType = .none
        cellPremium.accessoryType = .none
        
        if let current = SubscriptionService.shared.currentSubscription, current.isActive {
            switch current.productId {
            case SubscriptionID.Standard:
                cellStandard.accessoryType = .checkmark
            case SubscriptionID.Premium:
                cellPremium.accessoryType = .checkmark
            default:
                break
            }
        } else if fromSettings {
            cellFree.accessoryType = .checkmark
        }
    }
    
    private func subscribe(to type: String) {
        var found: Bool = false
        
        viewActivity?.startAnimating()
        
        for subscription in SubscriptionService.shared.options ?? [] {
            if subscription.product.productIdentifier == type {
                found = true
                // setup purchase notifications
                
                NotificationCenter.default.addObserver(self, selector: #selector(purchaseFailed(_:)), name: SubscriptionService.userCancelledNotification, object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(purchaseComplete), name: SubscriptionService.purchaseSuccessfulNotification, object: nil)
                
                // make purchase
                SubscriptionService.shared.purchase(subscription: subscription)
            }
        }
        
        if !found {
            let alert = UIAlertController(title: "Unable to Complete Purchase", message: "Check that you have a valid internet connection, and try again.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true) {
                self.viewActivity?.stopAnimating()
            }
            return
        }
    }
    
    // MARK: - Enable Restore
    
    func restorePurchasesTapped(_ sender: Any) {
        print("~>Restore purchases")
        restoreFromButton = true
        
        viewActivity?.startAnimating()
        view.isUserInteractionEnabled = false
        
        // setup purchase notifications
        
        NotificationCenter.default.addObserver(self, selector: #selector(purchaseFailed(_:)), name: SubscriptionService.userCancelledNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(purchaseComplete), name: SubscriptionService.restoreSuccessfulNotification, object: nil)
        
        SubscriptionService.shared.restorePurchases()
    }
    
    // MARK: - Subscription Notification Handling
    
    private func notificationReceived() {
        NotificationCenter.default.removeObserver(self, name: SubscriptionService.userCancelledNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: SubscriptionService.purchaseSuccessfulNotification, object: nil)
        
        DispatchQueue.main.async {
            self.viewActivity?.stopAnimating()
            self.view.isUserInteractionEnabled = true
        }
    }
    
    @objc private func purchaseComplete() {
        notificationReceived()
        
        // a new subscription so add credits and set renew date to today
        if !restoreFromButton {
            let date = Date(timeInterval: -1800, since: Date())
            CharmUser.shared.userProfile.renewDate = date
        }
        
        createAlert(withTitle: restoreFromButton ? "Restore Complete" : "Purchase Complete", andMessage: restoreFromButton ? "Your purchase has been restored." : "Congratulations on your purchase!  You may cancel anytime through iTunes.", andDoneButton: "Great!", purchased: true)
    }
    
    @objc private func purchaseFailed(_ sender: Notification) {
        notificationReceived()
        guard let error = sender.object as? SKError else {
            if restoreFromButton {
                restoreFromButton = false
                createAlert(withTitle: "Restore Failed", andMessage: "Could not find any purchases to restore.  Check your subscriptions in iTunes.", andDoneButton: "OK")
            } else {
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
            return
        default:
            createAlert(withTitle: "Unknown Error", andMessage: "An unknown error has occured, please check that you are logged into the iTunes store and that you have an internet connection.", andDoneButton: "OK")
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
                    } else {
                        self.saveUserProfileToFirebase()
                    }
                    
                    NotificationCenter.default.post(name: FirebaseNotification.CharmUserDidUpdate, object: nil)
                    
                    self.dismiss(animated: true) {
                        if !self.fromSettings, let vc = self.parentView {
                            vc.showNavigation()
                        }
                    }
                }
            }))
            self.present(successAlert, animated: true, completion: nil)
        }
        
    }
    
    // Update status of user
    
    private func saveUserProfileToFirebase() {
        
        guard CharmUser.shared != nil, let id = CharmUser.shared.id else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                self.saveUserProfileToFirebase()
                return
            }
            return
        }
        
        let profile = CharmUser.shared.userProfile
        
        do {
            let data = try FirebaseEncoder().encode(profile)
            Database.database().reference().child(FirebaseStructure.Users).child(id).child(FirebaseStructure.CharmUser.Profile).setValue(data)
            print("~>Set user profile with new date")
        } catch let error {
            print("~>There was an error: \(error)")
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 3
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cid = tableView.cellForRow(at: indexPath)?.reuseIdentifier else {
            tableView.deselectRow(at: indexPath, animated: false)
            print("~>No cell id")
            return
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch cid {
        case CellID.Free:
            if !fromSettings {
                parentView?.showNavigation()
                return
            } else if let cell = tableView.cellForRow(at: indexPath), cell.accessoryType == .none {
                let cancelAlert = UIAlertController(title: "Cancel Subscription", message: "You currently have a subscription. You will need to cancel your subscription first. Once your subscription expires, you will automatically be put back on the free plan.", preferredStyle: .alert)
                cancelAlert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                cancelAlert.addAction(UIAlertAction(title: "Show Me How", style: .default, handler: { (_) in
                    guard let link = URL(string: "https://support.apple.com/en-us/HT202039") else { return }
                    UIApplication.shared.open(link, options: [:], completionHandler: nil)
                }))
                
                present(cancelAlert, animated: true, completion: nil)
            }
        case CellID.Standard:
            subscribe(to: SubscriptionID.Standard)
        case CellID.Premium:
            subscribe(to: SubscriptionID.Premium)
        default:
            print("~>Did not tap a supported cell")
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return fromSettings ? "Update Your Membership" : ""
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }

}
