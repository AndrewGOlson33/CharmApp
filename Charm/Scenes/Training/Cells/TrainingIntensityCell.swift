//
//  TrainingIntensityCell.swift
//  Charm
//
//  Created by Mobile Master on 7/16/20.
//  Copyright © 2020 Charm, LLC. All rights reserved.
//

import UIKit

class TrainingIntensityCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var overView: UIView!
    @IBOutlet weak var bottomLineView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        overView.layer.borderWidth = 2
        overView.layer.borderColor = UIColor(hex: "7753B5").cgColor
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setMarked(_ marked: Bool) {
        overView.isHidden = !marked
        titleLabel.textColor = marked ? UIColor(hex: "7753B5") : .black
    }
}
