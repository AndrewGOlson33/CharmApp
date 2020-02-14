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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        btnCreateAccount.layer.cornerRadius = btnCreateAccount.bounds.height / 2
        
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
}
