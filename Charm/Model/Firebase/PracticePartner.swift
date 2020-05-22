//
//  PracticePartner.swift
//  Charm
//
//  Created by Игорь on 18.0520..
//  Copyright © 2020 Charm, LLC. All rights reserved.
//

import Foundation

class PracticePartner {
    
    var name: String
    var videos: [PracticeVideo]
    
    
    init(name: String, videos: [PracticeVideo]) {
        self.name = name
        self.videos = videos
    }
}


class PracticeVideo {
    
    enum PracticeVideoType: String {
        case question = "Q"
        case answer = "A"
    }
    
    var id: String
    var type: PracticeVideoType
    var url: URL
    
    init(id: String, type: PracticeVideoType, url: URL) {
        self.id = id
        self.type = type
        self.url = url
    }
}
