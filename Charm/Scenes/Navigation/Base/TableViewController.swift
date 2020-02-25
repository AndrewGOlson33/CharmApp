//
//  TableViewController.swift
//  Charm
//
//  Created by Andrii Hlukhanyk on 25.02.2020.
//  Copyright © 2020 Charm, LLC. All rights reserved.
//

import MBProgressHUD
import UIKit

class TableViewController: UITableViewController {
    
    // MARK: - Public methods
    
    func showActivityIndicator() {
        MBProgressHUD.showAdded(to       : self.view,
                                animated : true)
        UIApplication.shared.beginIgnoringInteractionEvents()
    }
    
    func hideActivityIndicator() {
        MBProgressHUD.hide(for      : self.view,
                           animated : true)
        UIApplication.shared.endIgnoringInteractionEvents()
    }
}
