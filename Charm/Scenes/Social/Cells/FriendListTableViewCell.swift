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

    @IBOutlet weak var imgProfile: UIImageView!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblEmail: UILabel!
    @IBOutlet weak var lblDetail: UILabel!
    @IBOutlet weak var btnApprove: UIButton!
    
    // MARK: - Properties
    var id: String!
    var delegate: ApproveFriendDelegate?
    
    // MARK: - Button Handling
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // setup button's border
        btnApprove.layer.borderColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
        btnApprove.layer.borderWidth = 1
        btnApprove.layer.cornerRadius = btnApprove.bounds.height / 2
        
        imgProfile.layer.cornerRadius =  imgProfile.frame.height / 2
        imgProfile.clipsToBounds = true
    }
    
    @IBAction func approveButtonTapped(_ sender: Any) {
        // When button is tapped
        delegate?.approveFriendRequest(withId: id)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // make sure profile image doesn't get confused with other cells
        imgProfile.image = nil
        imgProfile.layer.cornerRadius = 0
    }
    
}
