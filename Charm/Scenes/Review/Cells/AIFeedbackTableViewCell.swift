//
//  AIFeedbackTableViewCell.swift
//  Charm
//
//  Created by Daniel Pratt on 8/19/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit

class AIFeedbackTableViewCell: UITableViewCell {
    
    @IBOutlet weak var lblFeedback: UILabel!
    
    var feedbackText: String = "" {
        didSet {
            lblFeedback.text = feedbackText
            updateSize()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        if feedbackText != "" {
            lblFeedback.text = feedbackText
            updateSize()
        }
    }
    
    override func prepareForReuse() {
        lblFeedback.text = feedbackText
        updateSize()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    private func updateSize() {
        lblFeedback.sizeToFit()
        setNeedsLayout()
    }

}
