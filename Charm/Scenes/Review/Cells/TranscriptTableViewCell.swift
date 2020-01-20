//
//  TranscriptTableViewCell.swift
//  Charm
//
//  Created by Daniel Pratt on 3/19/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit

class TranscriptTableViewCell: UITableViewCell {

    @IBOutlet weak var lblTranscriptText: UILabel!
    @IBOutlet weak var viewBubble: UIView!
    
    func setup(with info: TranscriptCellInfo) {
        // setup things in the ui that will be the same
        lblTranscriptText.attributedText = info.text
        lblTranscriptText.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        viewBubble.layer.cornerRadius = 16
        
        // setup specific case items
        if info.isUser { setupForUser() } else { setupForOther() }
    }
    
    private func setupForUser() {
        lblTranscriptText.textAlignment = .right
        viewBubble.backgroundColor = #colorLiteral(red: 0.4139811397, green: 0.7173617482, blue: 0.9456090331, alpha: 1)
        viewBubble.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMinXMinYCorner]
    }
    
    private func setupForOther() {
        lblTranscriptText.textAlignment = .left
        viewBubble.backgroundColor = #colorLiteral(red: 0.4756349325, green: 0.4756467342, blue: 0.4756404161, alpha: 1)
        viewBubble.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
    }
    
}
