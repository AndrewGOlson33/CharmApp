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
    
    // layout constraints
    
    @IBOutlet var isUserConstraints: [NSLayoutConstraint]!
    @IBOutlet var isFriendConstraints: [NSLayoutConstraint]!
    
    func setup(with info: TranscriptCellInfo) {
        // setup things in the ui that will be the same
        lblTranscriptText.attributedText = info.text
        lblTranscriptText.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        viewBubble.backgroundColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
        viewBubble.layer.cornerRadius = 16
        
        // setup specific case items
        if info.isUser { setupForUser() } else { setupForOther() }
    }
    
    private func setupForUser() {
        lblTranscriptText.textAlignment = .right
//        viewBubble.backgroundColor = #colorLiteral(red: 0.4139811397, green: 0.7173617482, blue: 0.9456090331, alpha: 1)
        viewBubble.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMinXMinYCorner]
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            NSLayoutConstraint.activate(self.isUserConstraints)
            NSLayoutConstraint.deactivate(self.isFriendConstraints)
        }
    }
    
    private func setupForOther() {
        lblTranscriptText.textAlignment = .left
        viewBubble.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            NSLayoutConstraint.activate(self.isFriendConstraints)
            NSLayoutConstraint.deactivate(self.isUserConstraints)
        }
    }
}
