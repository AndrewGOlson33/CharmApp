//
//  ScaleBar.swift
//  Charm
//
//  Created by Daniel Pratt on 3/19/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit

enum SliderType {
    case standard, fixed
}

class SliderView: UIView {
    
    // MARK: - Properties
    
    // universal corner radius
    private let cornerRadius: CGFloat = 4.0
    
    var type: SliderType = .standard
    var position: CGFloat = 0.0
    var barStartPosition: CGFloat = 0.0
    var barEndPosition: CGFloat = 0.0
    
    // Views that make up slider
    var backgroundView: UIView!
    var barView: UIView!
    var positionView: UIView!
    
    var color: UIColor = #colorLiteral(red: 0.4862745098, green: 0.7098039216, blue: 0.9254901961, alpha: 1)
    var barBackgroundColor: UIColor {
        didSet {
            guard let backgroundView = backgroundView else { return }
            backgroundView.backgroundColor = barBackgroundColor
        }
    }
    
    // gets set to true after setup completes
    private(set) var isSetup: Bool = false
    
    // constants
    let animationDuration = 0.25
    
    // MARK: - Init Methods
    
    override init(frame: CGRect) {
        barBackgroundColor = #colorLiteral(red: 0.7450134158, green: 0.7451456189, blue: 0.7450150251, alpha: 1)
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        type = .standard
        barBackgroundColor = #colorLiteral(red: 0.7450134158, green: 0.7451456189, blue: 0.7450150251, alpha: 1)
        super.init(coder: coder)
    }
    
    // MARK: - Setup methods
    
    func setup(for type: SliderType, atPosition position: CGFloat, barStart start: CGFloat = 0.0, end: CGFloat = 0.0, color: UIColor) {
        self.type = type
        self.position = position
        barStartPosition = start
        barEndPosition = end > 0.0 ? end : position
        self.color = color
        
        setupBackground()
        if type == .fixed { setupPositionIndicator() }
        setupBackgroundBars()
        
        isSetup = true
    }
    
    private func setupBackground() {
        guard !isSetup else { return }
        // frame background should be clear
        backgroundColor = .clear
        
        backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        backgroundView.clipsToBounds = true
        backgroundView.layer.cornerRadius = cornerRadius
        backgroundView.backgroundColor = barBackgroundColor
        addSubview(backgroundView)
        
        // add constraints
        self.addConstraints([
            NSLayoutConstraint(item: backgroundView!, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: backgroundView!, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: backgroundView!, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: backgroundView!, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1.0, constant: 0)
        ])
        
    }
    
    private func setupPositionIndicator() {
        guard !isSetup else { return }
        let height = frame.height * 1.5
        let startingPosition = (position * frame.width) - 2
        positionView = UIView(frame: CGRect(x: startingPosition, y: 0 - frame.height * 0.25, width: 4, height: height))
        if #available(iOS 12.0, *) {
            positionView.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .white : .black
        } else {
            positionView.backgroundColor = .black
        }
        positionView.layer.cornerRadius = 2
        addSubview(positionView)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        guard positionView != nil else { return }
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                positionView.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .white : .black
                positionView.setNeedsLayout()
            }
        } else {
            return
        }
    }
    
    private func setupBackgroundBars() {
        guard !isSetup else { return }
        switch type {
        case .standard:
            setupStandard(animated: false)
        case .fixed:
            setupFixed()
        }
    }
    
    private func setupStandard(animated: Bool = true) {
        guard barStartPosition >= 0.0 && barEndPosition <= 1.0 else { print("~>Invalid bounds, values must be between 0.0 and 1.0."); return }
        
        if animated {
             UIView.animate(withDuration: animationDuration, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.0, options: [.curveEaseOut], animations: { [weak self] in
                guard let self = self else { return }
                self.drawBar()
            }, completion: nil)
        } else {
            drawBar()
        }
    }
    
    private func drawBar() {
        let startingX = barStartPosition * frame.width
        let endingX = barEndPosition * frame.width
        let width = endingX - startingX
        
        let barFrame = CGRect(x: startingX, y: 0, width: width, height: frame.height)
        
        if barView == nil {
            barView = UIView(frame: barFrame)
            barView.backgroundColor = color
            barView.layer.cornerRadius = cornerRadius
            backgroundView.addSubview(barView)
            backgroundView.bringSubviewToFront(barView)
        } else {
            barView.frame = barFrame
        }
    }
    
    private func setupFixed() {
        guard !isSetup else { return }
        
        drawBar()
    }
    
    // MARK: - Functions to update and animate view
    
    func updatePosition(to: CGFloat) {
        position = to
        
        switch type {
        case .standard:
            if position > 0.0,
                position > barEndPosition {
                barEndPosition = position
            }
            setupStandard(animated: true)
        case .fixed:
            // no animation is needed for the navy view so just break out of switch
            break
        }
        
        if positionView != nil {
            let moveToX = (position * frame.width) - (positionView.frame.width / 2)
            
            UIView.animate(withDuration: animationDuration, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.0, options: [.curveEaseOut], animations: {
                self.positionView.frame.origin.x = moveToX
            }, completion: nil)
        }
    }
}
