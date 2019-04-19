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
        outterView.setGradientBackground(colorTop: .white, colorBottom: #colorLiteral(red: 0.7843906283, green: 0.784409225, blue: 0.7843992114, alpha: 1))
        outterView.clipsToBounds = true
        outterView.layer.cornerRadius = outterFrame.height * 0.33
                
        self.frame = CGRect(origin: CGPoint(x: originalFrame.origin.x, y: originalFrame.origin.y), size: CGSize(width: outterFrame.width, height: outterFrame.height))
        addSubview(outterView)
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
    
}
