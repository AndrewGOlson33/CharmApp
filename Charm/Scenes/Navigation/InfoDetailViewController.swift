//
//  InfoDetailViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 7/8/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit

enum InfoDetail {
    case Emotions, Conversation, Ideas, Connection
}

class InfoDetailViewController: UIViewController {
    
    // MARK: - Tutorial Views
    
    @IBOutlet weak var txtEmotions: UITextView!
    @IBOutlet weak var txtConversation: UITextView!
    @IBOutlet weak var txtIdeas: UITextView!
    @IBOutlet weak var txtConnection: UITextView!
    
    // MARK: - Properties
    
    var type: InfoDetail? = nil
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // make sure everythign is hidden
        txtEmotions.isHidden = true
        txtConversation.isHidden = true
        txtIdeas.isHidden = true
        txtConnection.isHidden = true
        
        // make sure the detail type has been set, otherwise go back
        guard let detail = type else {
            tabBarController?.navigationController?.popViewController(animated: true)
            return
        }
        
        var title = "More Information"
        
        switch detail {
        case .Conversation:
            txtConversation.isHidden = false
            title = "Conversation"
        case .Connection:
            txtConnection.isHidden = false
            title = "Connection"
        case .Emotions:
            txtEmotions.isHidden = false
            title = "Emotions"
        case .Ideas:
            txtIdeas.isHidden = false
            title = "Ideas"
        }
        
        navigationItem.title = title
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
    }

}
