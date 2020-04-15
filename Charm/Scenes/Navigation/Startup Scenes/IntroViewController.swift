//
//  IntroViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 7/3/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit

class IntroViewController: UIViewController {

    @IBOutlet weak var btnCreateAccount: UIButton!
    @IBOutlet weak var signInButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        signInButton.layer.borderColor = UIColor(white: 1.0, alpha: 0.5).cgColor
        signInButton.layer.borderWidth = 2.0
        
        btnCreateAccount.layer.borderColor = UIColor(white: 1.0, alpha: 0.5).cgColor
        btnCreateAccount.layer.borderWidth = 2.0
        
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
}
