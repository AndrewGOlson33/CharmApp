//
//  SandboxViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 3/25/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit
import Speech

class SandboxViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    // MARK: - Properties
    
    let viewModel = ScorePhraseModel()
    
    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    // load navigation bar items
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.navigationItem.title = "Training Sandbox"
        let info = UIBarButtonItem(image: UIImage(named: Image.Info), style: .plain, target: self, action: #selector(infoButtonTapped))
        tabBarController?.navigationItem.rightBarButtonItem = info
    }
    
    // MARK: - Private Helper Functions
    
    @objc private func infoButtonTapped() {
        print("~>Info button tapped.")
    }

}
