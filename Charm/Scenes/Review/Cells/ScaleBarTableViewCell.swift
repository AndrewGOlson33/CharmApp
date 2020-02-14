//
//  ScaleBarTableViewCell.swift
//  Charm
//
//  Created by Daniel Pratt on 3/19/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit

class ScaleBarTableViewCell: UITableViewCell {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var sliderView: SliderView!
    @IBOutlet weak var lblDescription: UILabel!
    @IBOutlet weak var lblHint: UILabel!
    @IBOutlet weak var lblScore: UILabel!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
