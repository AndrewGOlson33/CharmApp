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
    case RedRightHalf
}

class ScaleBar: UIView {
    
    var type: BarType = .Green
    
    var value: Double = -1.0
    var calculatedValue: Double = 0.5
    
    let greenColors: [UIColor] = [#colorLiteral(red: 0.9943112372, green: 0.9765252471, blue: 0.9763546586, alpha: 1), #colorLiteral(red: 0, green: 0.6454889178, blue: 0.4457359314, alpha: 1), #colorLiteral(red: 0.2968337834, green: 0.4757083654, blue: 0.2566408515, alpha: 1), #colorLiteral(red: 0.04722579569, green: 0.3977198601, blue: 0.1387369335, alpha: 1)]
    let blueColors: [UIColor] = [#colorLiteral(red: 0.3418416381, green: 0.6355850101, blue: 0.9122640491, alpha: 1), #colorLiteral(red: 0.3310806155, green: 0.6119198799, blue: 0.8886095881, alpha: 1), #colorLiteral(red: 0.316000998, green: 0.5882632136, blue: 0.8649668694, alpha: 1)]
    
    // location dot
    var scoreLocation: UIView? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setupBar(ofType type: BarType,withValue value: Double, andLabelPosition labelValue: Double) {
        self.type = type
        self.value = value
        calculatedValue = labelValue
        setupBar()
    }
    
    func getStringValue(showPercentOnGreen: Bool = false) -> String {
        if type == .Green && !showPercentOnGreen {
            return "\(value)"
        } else {
            let percent = Int(value * 100)
            return "\(percent)%"
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
        
        switch type {
        case .Green:
            setupGreenBar()
        case .BlueRight:
            setupBlueRightBar()
        case .BlueCenter:
            setupBlueCenter()
        case .RedRightHalf:
            setupRedRightHalf()
        }
        
        setupScoreLocation()
        
    }
    
    // set score location
    
    func update(withValue value: Double, andCalculatedValue calculated: Double) {
        self.value = value
        calculatedValue = calculated
        
        setupScoreLocation()
    }
    
    fileprivate func setupScoreLocation() {
        if scoreLocation != nil {
            scoreLocation?.removeFromSuperview()
        }
        scoreLocation = calculatedValue == 0 ? UIView(frame: CGRect(x: frame.width * CGFloat(calculatedValue) + (frame.height / 2), y: frame.height / 4, width: frame.height / 2, height: frame.height / 2)) : UIView(frame: CGRect(x: frame.width * CGFloat(calculatedValue) - (frame.height / 2), y: frame.height / 4, width: frame.height / 2, height: frame.height / 2))
        
        scoreLocation!.backgroundColor = .black
        scoreLocation!.layer.cornerRadius = scoreLocation!.frame.height / 2
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
    
    private func setupRedRightHalf() {
        let width = frame.width
        let segmentWidth = width / 2
        
        for index in 0...1 {
            let segmentFrame = CGRect(origin: CGPoint(x: CGFloat(index) * segmentWidth, y: 0), size: CGSize(width: segmentWidth, height: frame.height))
            let segment = UIView(frame: segmentFrame)
            let segmentColor: UIColor = index == 0 ? .white : .red
            
            segment.backgroundColor = segmentColor
            addSubview(segment)
        }
        
    }
}
