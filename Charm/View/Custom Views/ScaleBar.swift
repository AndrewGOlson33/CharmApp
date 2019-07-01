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

enum SliderType {
    case fillFromLeft, fixed, fillFromRight
}

class SliderView: UIView {
    
    // MARK: - Properties
    
    var type: SliderType = .fillFromLeft
    var position: CGFloat = 0.0
    var minBluePosition: CGFloat = 0.0
    var maxBluePosition: CGFloat = 0.0
    var minRedPosition: CGFloat? = nil
    var maxRedPosition: CGFloat? = nil
    
    // Views that make up slider
    var backgroundView: UIView!
    var navyView: UIView!
    var redView: UIView? = nil
    var positionView: UIView!
    
    // gets set to true after setup completes
    var isSetup: Bool = false
    
    // constants
    let animationDuration = 0.25
    
    // MARK: - Init Methods
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        self.type = .fillFromLeft
        super.init(coder: coder)
    }
    
    // MARK: - Setup methods
    
    func setup(for type: SliderType, at position: CGFloat = 0.0, minBlue: CGFloat = 0.0, maxBlue: CGFloat = 1.0, minRed: CGFloat? = nil, maxRed: CGFloat? = nil) {
        self.type = type
        self.position = position
        minBluePosition = minBlue
        maxBluePosition = maxBlue
        minRedPosition = minRed
        maxRedPosition = maxRed
        
        setupBackground()
        setupPositionIndicator()
        setupNavyView()
        
        isSetup = true
    }
    
    private func setupBackground() {
        guard !isSetup else { return }
        // frame background should be clear
        backgroundColor = .clear
        
        backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height))
        backgroundView.clipsToBounds = true
        backgroundView.layer.cornerRadius = frame.height / 2
        backgroundView.backgroundColor = #colorLiteral(red: 0.9132656455, green: 0.9216780066, blue: 0.9215492606, alpha: 1)
        addSubview(backgroundView)
    }
    
    private func setupPositionIndicator() {
        guard !isSetup else { return }
        let size = frame.height * 1.2
        let startingPosition = (position * frame.width) - (size / 2)
        
        positionView = UIView(frame: CGRect(x: startingPosition, y: 0 - frame.height * 0.1, width: size, height: size))
        positionView.backgroundColor = .clear
        positionView.layer.shadowColor = UIColor.black.cgColor
        positionView.layer.shadowRadius = size * 0.1
        positionView.layer.shadowOpacity = 0.4
        positionView.layer.shadowOffset = CGSize(width: 0, height: 1)
        
        let borderView = UIView(frame: positionView.bounds)
        borderView.layer.cornerRadius = size / 2
        borderView.layer.masksToBounds = true
        borderView.backgroundColor = .white
        
        positionView.addSubview(borderView)
        addSubview(positionView)
    }
    
    private func setupNavyView() {
        guard !isSetup else { return }
        switch type {
        case .fillFromLeft:
            drawFillFromLeft(animated: false)
        case .fillFromRight:
            print("~>Fill from right not handled yet.")
        case .fixed:
            print("~>Fixed not handled yet.")
        }
    }
    
    private func setupRedView() {
        guard !isSetup else { return }
        guard let minRed = minRedPosition, let maxRed = maxRedPosition else { return }
        print("~>Min red: \(minRed) max red: \(maxRed)")
    }
    
    func updatePosition(to: CGFloat) {
        position = to
        let moveToX = (position * frame.width) - (positionView.frame.width / 2)
        
        
        switch type {
        case .fillFromLeft:
            drawFillFromLeft(animated: true)
        default:
            print("~>Other types are not yet supported.")
        }
        
        
        UIView.animate(withDuration: animationDuration, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.0, options: [.curveEaseOut], animations: {
            self.positionView.frame.origin.x = moveToX
        }, completion: nil)
    }
    
    private func drawFillFromLeft(animated: Bool = true) {
        // make sure min and max positions are between 0 and 1
        guard minBluePosition >= 0 && minBluePosition < 1 && maxBluePosition <= 1 && minBluePosition < maxBluePosition else {
            print("~>Invalid bounds.  Min: \(minBluePosition) Max: \(maxBluePosition)")
            return
        }
        
        // if position is below min blue, then there shouldn't be a blue line at all
        guard position >= minBluePosition else {
            if navyView != nil {
                navyView.removeFromSuperview()
                navyView = nil
            }
            return
        }
        
        let startingX = frame.width * minBluePosition
        let endX = position <= maxBluePosition ? frame.width * position : frame.width * maxBluePosition
        let width = endX - startingX
        
        let navyFrame = CGRect(x: startingX, y: 0, width: width, height: frame.height)
        
        if animated {
            UIView.animate(withDuration: animationDuration, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.0, options: [.curveEaseOut], animations: {
                if self.navyView == nil {
                    self.navyView = UIView(frame: navyFrame)
                    self.navyView.backgroundColor = #colorLiteral(red: 0.1323429346, green: 0.1735357642, blue: 0.2699699998, alpha: 1)
                    self.navyView.layer.cornerRadius = self.frame.height / 2
                    self.backgroundView.addSubview(self.navyView)
                    self.backgroundView.bringSubviewToFront(self.navyView)
                    return
                } else {
                    self.navyView.frame = navyFrame
                }
            }, completion: nil)
        } else {
            if navyView == nil {
                navyView = UIView(frame: navyFrame)
                navyView.backgroundColor = #colorLiteral(red: 0.1323429346, green: 0.1735357642, blue: 0.2699699998, alpha: 1)
                navyView.layer.cornerRadius = frame.height / 2
                backgroundView.addSubview(navyView)
                backgroundView.bringSubviewToFront(navyView)
                return
            } else {
                navyView.frame = navyFrame
            }
        }
    }
    
}
