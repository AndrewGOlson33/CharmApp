//
//  UpdateSubscriptionViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 7/3/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit

class UpdateSubscriptionViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var viewContainer: UIView!
    @IBOutlet weak var viewActivity: UIActivityIndicatorView!
    
    // MARK: - Properties

    override func viewDidLoad() {
        super.viewDidLoad()

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
            vc.fromSettings = true
        } else if segue.identifier == SegueID.showInfo, let infoVC = segue.destination as? InfoModuleViewController, let type = sender as? DocumentType {
            infoVC.documentType = type
        }
    }

}
