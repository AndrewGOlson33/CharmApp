//
//  TutorialCell.swift
//  Charm
//
//  Created by Игорь on 08.0520..
//  Copyright © 2020 Charm, LLC. All rights reserved.
//

import UIKit

class TutorialCell: UITableViewCell {

    @IBOutlet weak var shadowView: UIView!
    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var lessonNumberLabel: UILabel!
    @IBOutlet weak var lessonProgressLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var lessonTitleLabel: UILabel!
    
    
    var gradientAdded: Bool = false
    let gradient: CAGradientLayer = CAGradientLayer()
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        applyShadow(for: shadowView.layer)
        addGradient()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = gradientView.bounds
    }

    private func applyShadow(for layer: CALayer) {
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowOffset = CGSize(width: 1.0, height: 1.0)
        layer.shadowRadius = 5
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
        layer.cornerRadius = 5.0
    }
    
    func addGradient () {
        if !gradientAdded {
            if #available(iOS 13.0, *) {
                gradient.colors = [UIColor.systemBackground.withAlphaComponent(0.0).cgColor, UIColor.systemBackground.cgColor]
            } else {
                gradient.colors = [UIColor.white.withAlphaComponent(0.0).cgColor, UIColor.white.cgColor]
            }
            gradient.locations = [0.0 , 1.0]
            gradient.startPoint = CGPoint(x: 0.0, y: 0.5)
            gradient.endPoint = CGPoint(x: 1.0, y: 0.5)
            
            // temp fix for wrong gradient size
            gradient.frame = gradientView.bounds
            
            gradientView.layer.insertSublayer(gradient, at: 0)
            gradientAdded = true
        }
    }

}
