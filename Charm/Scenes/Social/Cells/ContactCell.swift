//
//  ContactCell.swift
//  Charm
//
//  Created by Игорь on 09.0520..
//  Copyright © 2020 Charm, LLC. All rights reserved.
//

import UIKit

class ContactCell: UITableViewCell {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        if profileImageView != nil { profileImageView.image = nil }
    }

}
