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
    var thumbnail: String
    
    // image to display
    func getThumbnailImage(completion: @escaping(_ image: UIImage?)->Void) {
        let storageRef = Storage.storage()
        storageRef.reference(forURL: thumbnail).downloadURL { (url, error) in
            if let error = error {
                print("~>Error getting reference url: \(error)")
                completion(nil)
            }
            
            let data = try? Data(contentsOf: url!)
            if let realData = data {
                completion(UIImage(data: realData))
            } else {
                completion(nil)
            }
        }
        
    }
    
}
