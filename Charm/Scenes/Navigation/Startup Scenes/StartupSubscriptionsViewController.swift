//
//  StartupSubscriptionsViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 7/3/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit

class StartupSubscriptionsViewController: UIViewController {
    
    @IBOutlet weak var viewActivity: UIActivityIndicatorView!
    
    var subscriptionView: SubscriptionsTableViewController? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    // MARK: - Button Handling
    
    @IBAction func restorePurchasesTapped(_ sender: Any) {
        print("~>Restore tapped.")
        subscriptionView?.restorePurchasesTapped(sender)
    }
    
    @IBAction func showTermsOfUse(_ sender: Any) {
        performSegue(withIdentifier: SegueID.showInfo, sender: DocumentType.TermsOfUse)
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // get container view controller
        if segue.identifier == SegueID.subscriptionTable, let vc = segue.destination as? SubscriptionsTableViewController {
            vc.viewActivity = viewActivity
            vc.fromSettings = false
            vc.parentView = self
            subscriptionView = vc
        } else if segue.identifier == SegueID.showInfo, let infoVC = segue.destination as? InfoModuleViewController, let type = sender as? DocumentType {
            infoVC.documentType = type
        }
    }
    
    func showNavigation() {
        DispatchQueue.main.async {
            let nav = self.storyboard?.instantiateViewController(withIdentifier: StoryboardID.navigationHome)
            let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
            // clear out any calls as needed
            appDelegate.window?.rootViewController = nav
            appDelegate.window?.makeKeyAndVisible()
        }
    }
 

}
