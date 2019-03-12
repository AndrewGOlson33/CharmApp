//
//  ChatFriendListTableViewCell.swift
//  Charm
//
//  Created by Daniel Pratt on 3/12/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit

class ChatFriendListTableViewCell: UITableViewCell {
   
    // MARK: - IBOutlets
    
    @IBOutlet weak var imgProfile: UIImageView!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblEmail: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Setup profile picture to look circular
        imgProfile.layer.cornerRadius = imgProfile.frame.height / 2
        imgProfile.clipsToBounds = true
    }

    override func prepareForReuse() {
        imgProfile.image = nil
    }

}
