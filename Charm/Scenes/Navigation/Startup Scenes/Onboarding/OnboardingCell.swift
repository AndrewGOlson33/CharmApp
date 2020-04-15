//
//  OnboardingCell.swift
//  Charm
//
//  Created by Игорь on 15.0420..
//  Copyright © 2020 Charm, LLC. All rights reserved.
//

import UIKit

class OnboardingCell: UICollectionViewCell {
    
    @IBOutlet weak var contrainerView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    
    override class func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
}
