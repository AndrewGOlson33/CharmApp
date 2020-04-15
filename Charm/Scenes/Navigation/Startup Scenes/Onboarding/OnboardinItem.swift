//
//  OnboardinItem.swift
//  Charm
//
//  Created by Игорь on 15.0420..
//  Copyright © 2020 Charm, LLC. All rights reserved.
//

import Foundation
import UIKit

class OnboardingItem {
    
    var title: String
    var description: String
    
    var image: UIImage?
    var videoURL: String?
    
    init(title: String, descritpion: String, image: UIImage?, videoURL: String?) {
        self.title = title
        self.description = descritpion
        self.image = image
        self.videoURL = videoURL
    }
}
