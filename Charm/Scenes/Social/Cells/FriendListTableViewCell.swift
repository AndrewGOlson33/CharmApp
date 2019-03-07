//
//  FriendListTableViewCell.swift
//  Charm
//
//  Created by Daniel Pratt on 3/7/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit

class FriendListTableViewCell: UITableViewCell {
    
    // MARK: - IBOutlets

    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblEmail: UILabel!
    @IBOutlet weak var lblDetail: UILabel!
    @IBOutlet weak var btnApprove: UIButton!
    
    // MARK: - Properties
    var id: String!
    var delegate: ApproveFriendDelegate?
    
    // MARK: - Button Handling
    
    @IBAction func approveButtonTapped(_ sender: Any) {
        // When button is tapped
        delegate?.approveFriendRequest(withId: id)
    }
    
}
