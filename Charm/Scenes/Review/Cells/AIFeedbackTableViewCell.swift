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
    @IBOutlet weak var lblRecommendedTraining: UILabel!
    
    var feedbackText: String = "No feedback available." {
        didSet {
            lblFeedback.text = feedbackText
            updateSize()
        }
    }
    
    var recommendedTrainingText: String = "No training recommended." {
        didSet {
            lblRecommendedTraining.text = recommendedTrainingText
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        if feedbackText != "" {
            lblFeedback.text = feedbackText
            updateSize()
        }
        
        if recommendedTrainingText != "" {
            lblRecommendedTraining.text = recommendedTrainingText
            updateSize()
        }
    }
    
    override func prepareForReuse() {
        lblFeedback.text = feedbackText
        lblRecommendedTraining.text = recommendedTrainingText
        updateSize()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    private func updateSize() {
        lblFeedback.sizeToFit()
        lblRecommendedTraining.sizeToFit()
        setNeedsLayout()
    }
}
