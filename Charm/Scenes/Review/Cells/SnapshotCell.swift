//
//  SnapshotCell.swift
//  Charm
//
//  Created by Игорь on 15.0520..
//  Copyright © 2020 Charm, LLC. All rights reserved.
//

import UIKit

class SnapshotCell: UITableViewCell {
    
    @IBOutlet weak var shadowView: UIView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var ideaClarityProgressLabel: UILabel!
    @IBOutlet weak var ideaClarityProgressBar: UIProgressView!
    @IBOutlet weak var conversationFlowProgressBar: UIProgressView!
    @IBOutlet weak var conversationFlowProgressLabel: UILabel!
    @IBOutlet weak var personalBondProgressBar: UIProgressView!
    @IBOutlet weak var personalBondProgressLabel: UILabel!
    @IBOutlet weak var emotionsProgressBar: UIProgressView!
    @IBOutlet weak var emotionsProgressLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        applyShadow(for: shadowView.layer)
    }

    
    private func applyShadow(for layer: CALayer) {
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.25
        layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        layer.shadowRadius = 2.0
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
        layer.cornerRadius = 5.0
    }

}
