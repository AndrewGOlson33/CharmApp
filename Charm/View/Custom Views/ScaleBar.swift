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
}

class ScaleBar: UIView {
    
    var type: BarType = .Green
    
    var value: Double = -1.0
    var calculatedValue: Double = 0.5
    
    let greenColors: [UIColor] = [#colorLiteral(red: 0.9943112372, green: 0.9765252471, blue: 0.9763546586, alpha: 1), #colorLiteral(red: 0, green: 0.6454889178, blue: 0.4457359314, alpha: 1), #colorLiteral(red: 0.2968337834, green: 0.4757083654, blue: 0.2566408515, alpha: 1), #colorLiteral(red: 0.04722579569, green: 0.3977198601, blue: 0.1387369335, alpha: 1)]
    let blueColors: [UIColor] = [#colorLiteral(red: 0.3758323301, green: 0.8713353419, blue: 1, alpha: 1), #colorLiteral(red: 0.3310806155, green: 0.6119198799, blue: 0.8886095881, alpha: 1), #colorLiteral(red: 0.2170320999, green: 0.414364606, blue: 0.6126014209, alpha: 1)]
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setupBar(ofType type: BarType,withValue value: Double) {
        self.type = type
        self.value = value
        setupBar()
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
            print("~>Green")
            setupGreenBar()
        case .BlueRight:
            print("~>Blue Right")
            setupBlueRightBar()
        case .BlueCenter:
            print("~>Blue Center")
            setupBlueCenter()
        }
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
}
