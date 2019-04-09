//
//  LableBubbleView.swift
//  Charm
//
//  Created by Daniel Pratt on 4/8/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit

class LabelBubbleView: UIView {
    
    private var labelText: String
    private var label: UILabel? = nil
    private var originalFrame: CGRect
    
    init(frame: CGRect, withText text: String) {
        labelText = text
        originalFrame = frame
        super.init(frame: .zero)
        backgroundColor = .clear
        
        drawView()
    }
    
    func updateLabel(withText text: String, frame: CGRect? = nil) {
        // clear old
        for view in self.subviews {
            view.removeFromSuperview()
        }
        
        if let frame = frame { originalFrame = frame }
        labelText = text
        
        drawView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private Helper Functions
    
    // Sets up View
    
    private func drawView() {
        // setup label
        self.label = UILabel(frame: .zero)
        self.label?.font = self.label?.font.withSize(12)
        self.label?.textAlignment = .center
        self.label?.text = labelText
        
        let labelFrame = self.label?.intrinsicContentSize
        
        // setup outter frame
        let outterFrame = CGRect(x: 0, y: 0, width: labelFrame!.width + 8, height: originalFrame.height)
        self.label?.frame = outterFrame
        let outterView = UIView(frame: outterFrame)
        outterView.addSubview(self.label!)
//        outterView.backgroundColor = #colorLiteral(red: 0.7843906283, green: 0.784409225, blue: 0.7843992114, alpha: 1)
        setGradientBackground(colorTop: .white, colorBottom: #colorLiteral(red: 0.7843906283, green: 0.784409225, blue: 0.7843992114, alpha: 1), into: outterView)
        outterView.clipsToBounds = true
        outterView.layer.cornerRadius = outterFrame.height * 0.33
        
        // get frame values
//        let frameWidth = outterFrame.width
//        let frameHeight = outterFrame.height * 1.25
//        var frameX = originalFrame.origin.x - labelFrame!.width * 0.5 + 4
//        let frameY = originalFrame.origin.y - frameHeight
//
//        if frameX < 8 { frameX = 8.0 }
//        if frameX > UIScreen.main.bounds.width - 8 - frameWidth {
//            frameX = UIScreen.main.bounds.width - 8 - frameWidth
//        }
        
        self.frame = CGRect(origin: originalFrame.origin, size: CGSize(width: outterFrame.width, height: outterFrame.height))
        addSubview(outterView)
        
//        // Setup Triangle
//        let triangleWidth = outterFrame.width * 0.2
//        let triangleHeight: CGFloat = 16
//        let triangleX = self.frame.width / 5
//        let triangleY = labelFrame!.height / 2 + 0.95
//        let triangle = drawTriangle(insideRect: CGRect(x: triangleX, y: triangleY, width: triangleWidth, height: triangleHeight))
//        addSubview(triangle)
    }
    
    // Draws the downward triangle
    private func drawTriangle(insideRect rect: CGRect) -> UIView {
        let triangle = CAShapeLayer()
        let view = UIView(frame: rect)
        triangle.lineJoin = .round
        triangle.fillColor = #colorLiteral(red: 0.7843906283, green: 0.784409225, blue: 0.7843992114, alpha: 1)
        
        // draw triangle path
        let path = UIBezierPath()
        path.move(to: CGPoint(x: rect.origin.x, y: rect.origin.y))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.origin.y))
        path.close()
        triangle.path = path.cgPath
        view.layer.addSublayer(triangle)
        return view
    }
    
    // setup gradient layer
    
    private func setGradientBackground(colorTop: UIColor, colorBottom: UIColor, into view: UIView) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [colorBottom.cgColor, colorTop.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.locations = [0, 1]
        gradientLayer.frame = view.bounds
        
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
}
