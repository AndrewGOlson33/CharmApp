//
//  SubscriptionsViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 4/19/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit

class SubscriptionsViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var outterView: UIView!
    
    // MARK: - Properties
    
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
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}

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

}
