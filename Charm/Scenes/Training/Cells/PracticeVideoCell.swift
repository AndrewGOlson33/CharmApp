//
//  PracticeVideoCell.swift
//  Charm
//
//  Created by Игорь on 19.0520..
//  Copyright © 2020 Charm, LLC. All rights reserved.
//

import UIKit

class PracticeVideoCell: UITableViewCell {
    
    @IBOutlet weak var shadowView: UIView!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var instaLabel: UILabel!
    @IBOutlet weak var sloganLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        applyShadow(for: shadowView.layer)
    }
    
    
    private func applyShadow(for layer: CALayer) {
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        layer.shadowRadius = 3.0
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
        layer.cornerRadius = 5.0
    }

}
