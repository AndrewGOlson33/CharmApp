//
//  ScaleBar.swift
//  Charm
//
//  Created by Daniel Pratt on 3/19/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit

enum BarType {
    case Green
    case BlueRight
    case BlueCenter
    case RedRightQuarter
}

enum LabelType {
    case NA
    case Percent
    case RawValue
    case IntValue
}

class ScaleBar: UIView {
    
    var type: BarType = .Green
    var labelType: LabelType = .NA
    
    var labelText: String {
        return getStringValue(forLabelType: labelType)
    }
    
    var value: Double = -1.0
    var calculatedValue: Double = 0.5
    
    let greenColors: [UIColor] = [#colorLiteral(red: 0.9943112372, green: 0.9765252471, blue: 0.9763546586, alpha: 1), #colorLiteral(red: 0, green: 0.6454889178, blue: 0.4457359314, alpha: 1), #colorLiteral(red: 0.2968337834, green: 0.4757083654, blue: 0.2566408515, alpha: 1), #colorLiteral(red: 0.04722579569, green: 0.3977198601, blue: 0.1387369335, alpha: 1)]
    let blueColors: [UIColor] = [#colorLiteral(red: 0.3418416381, green: 0.6355850101, blue: 0.9122640491, alpha: 1), #colorLiteral(red: 0.3310806155, green: 0.6119198799, blue: 0.8886095881, alpha: 1), #colorLiteral(red: 0.316000998, green: 0.5882632136, blue: 0.8649668694, alpha: 1)]
    
    // location dot
    var scoreLocation: LabelBubbleView? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setupBar(ofType type: BarType, withValue value: Double, andLabelPosition labelValue: Double) {
        self.type = type
        self.value = value
        calculatedValue = labelValue
        setupBar()
    }
    
    func getStringValue(showPercentOnGreen: Bool = false, showScoreOnOther: Bool = false) -> String {
        if type == .Green && !showPercentOnGreen {
            return "\(value)"
        } else if showScoreOnOther && type != .Green {
            return "\(Int(value))"
        } else if value < 1 {
            let percent = Int(value * 100)
            return "\(percent)%"
        } else {
            return value == 1.0 ? "100%" : "\(value)%"
        }
    }
    
    func getStringValue(forLabelType type: LabelType) -> String {
        switch type {
        case .NA:
            return "N/A"
        case .Percent:
            if value < 1 {
                let percent = Int(value * 100)
                return "\(percent)%"
            } else {
                return value == 1.0 ? "100%" : "\(value)%"
            }
        case .RawValue:
            return "\(value)"
        case .IntValue:
            return "\(Int(value))"
        }
    }
    
    // MARK: - Bar Setup Functions
    
    // Choose which bar to setup
    private func setupBar() {
        // no matter what the border will be the same
        layer.borderColor = UIColor.black.cgColor
        layer.borderWidth = 1.0
        layer.cornerRadius = frame.height / 2
        layer.masksToBounds = true
        clipsToBounds = false
        
        switch type {
        case .Green:
            setupGreenBar()
        case .BlueRight:
            setupBlueRightBar()
        case .BlueCenter:
            setupBlueCenter()
        case .RedRightQuarter:
            setupRedRightQuarter()
        }
        
//        setupScoreLocation()
        
    }
    
    // set score location
    
    func update(withValue value: Double, andCalculatedValue calculated: Double) {
        self.value = value
        calculatedValue = calculated
        
//        setupScoreLocation()
    }
    
    fileprivate func setupScoreLocation() {
        if scoreLocation != nil {
            scoreLocation?.removeFromSuperview()
        }
        
        scoreLocation = calculatedValue == 0 ? LabelBubbleView(frame: CGRect(x: frame.width * CGFloat(calculatedValue) + (frame.height / 2), y: -4, width: frame.height * 1.6, height: 24), withText: labelText) : LabelBubbleView(frame: CGRect(x: frame.width * CGFloat(calculatedValue) - (frame.height / 2), y: -4, width: frame.height * 1.6, height: 24), withText: labelText)
        
        if calculatedValue == 1.0 {
            scoreLocation!.frame.origin.x -= scoreLocation!.frame.width / 2 + (frame.height / 2)
        }
        
        scoreLocation?.backgroundColor = .white
        
        addSubview(scoreLocation!)
        bringSubviewToFront(scoreLocation!)
    }
    
    // setup function for green bar
    private func setupGreenBar() {
        let width = frame.width
        let segmentWidth = width / 4
        
        for index in 0 ..< 4 {
            let segmentFrame = CGRect(origin: CGPoint(x: CGFloat(index) * segmentWidth, y: 0), size: CGSize(width: segmentWidth, height: frame.height))
            let segment = UIView(frame: segmentFrame)
            let segmentColor: UIColor = greenColors[index]
            segment.backgroundColor = segmentColor
            
            if index == 0 || index == 3 {
                segment.clipsToBounds = true
                segment.layer.cornerRadius = self.layer.cornerRadius
                segment.layer.maskedCorners = index == 0 ? [.layerMinXMaxYCorner, .layerMinXMinYCorner] : [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]
            }
            
            
            addSubview(segment)
        }
    }
    
    // setup function for blue right bar
    private func setupBlueRightBar() {
        let width = frame.width
        let segmentWidth = width / 6
        
        for index in 0 ..< 6 {
            
            let segmentFrame = CGRect(origin: CGPoint(x: CGFloat(index) * segmentWidth, y: 0), size: CGSize(width: segmentWidth, height: frame.height))
            let segment = UIView(frame: segmentFrame)
            var segmentColor: UIColor = .white
            
            if index == 0 || index == 5 {
                segment.clipsToBounds = true
                segment.layer.cornerRadius = self.layer.cornerRadius
                segment.layer.maskedCorners = index == 0 ? [.layerMinXMaxYCorner, .layerMinXMinYCorner] : [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]
                if index == 5 {
                    segment.frame = CGRect(x: segment.frame.origin.x - 1, y: segment.frame.origin.y, width: segment.frame.width + 1, height: segment.frame.height)
                }
            }
            
            // setup color
            switch index {
            case 3:
                segmentColor = blueColors[0]
            case 4:
                segmentColor = blueColors[1]
            case 5:
                segmentColor = blueColors[2]
            default:
                break
            }
            
            segment.backgroundColor = segmentColor
            addSubview(segment)
        }
    }
    
    // setup function for blue center bar
    private func setupBlueCenter() {
        let width = frame.width
        let segmentWidth = width / 48
        
        for index in 0 ..< 48 {
            let segmentFrame = CGRect(origin: CGPoint(x: CGFloat(index) * segmentWidth, y: 0), size: CGSize(width: segmentWidth, height: frame.height))
            let segment = UIView(frame: segmentFrame)
            var segmentColor: UIColor = .white
            
            if index == 0 || index == 48 {
                segment.clipsToBounds = true
                segment.layer.cornerRadius = self.layer.cornerRadius
                segment.layer.maskedCorners = index == 0 ? [.layerMinXMaxYCorner, .layerMinXMinYCorner] : [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]
            }
            
            switch index {
            case 15...17:
                segmentColor = blueColors[0]
            case 18...19:
                segmentColor = blueColors[1]
            case 20...27:
                segmentColor = blueColors[2]
            case 28...29:
                segmentColor = blueColors[1]
            case 30:
                segmentColor = blueColors[0]
            default:
                break
            }
            
            segment.backgroundColor = segmentColor
            addSubview(segment)
        }
    }
    
    private func setupRedRightQuarter() {
        let width = frame.width
        let segmentWidth = width / 4
        
        for index in 0...3 {
            let segmentFrame = CGRect(origin: CGPoint(x: CGFloat(index) * segmentWidth, y: 0), size: CGSize(width: segmentWidth, height: frame.height))
            let segment = UIView(frame: segmentFrame)
            let segmentColor: UIColor = index == 3 ? .red : .white
            
            if index == 0 || index == 3 {
                segment.clipsToBounds = true
                segment.layer.cornerRadius = self.layer.cornerRadius
                segment.layer.maskedCorners = index == 0 ? [.layerMinXMaxYCorner, .layerMinXMinYCorner] : [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]
            }
            
            segment.backgroundColor = segmentColor
            addSubview(segment)
        }
        
    }
}
