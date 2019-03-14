//
//  LearningVideo.swift
//  Charm
//
//  Created by Daniel Pratt on 3/14/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import Foundation
import CodableFirebase
import Firebase

struct VideoSections: Codable {
    var sections: [VideoSection] = []
}

struct VideoSection: Codable {
    var sectionTitle: String
    var videos: [LearningVideo]
}

struct LearningVideo: Codable {
    
    var title: String
    var url: String
    
}
