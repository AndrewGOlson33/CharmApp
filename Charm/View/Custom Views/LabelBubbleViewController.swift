//
//  LabelBubbleViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 3/19/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit

class LabelBubbleViewController: UIViewController {
    
    // MARK: - IBOutlet For Label
    @IBOutlet weak var label: UILabel!
    
    // text to set label with
    var labelText: String = "10.5"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Make sure the label text is set, otherwise don't show the view
        guard !labelText.isEmpty else {
            dismiss(animated: false, completion: nil)
            return
        }
 
        label.text = labelText
        
        preferredContentSize = CGSize(width: 56, height: 32)
    }
}
