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

class LearningVideo: Codable {
    
    var title: String
    var url: String
    var thumbnail: String
    
    private var imageData: Data?
    var thumbnailImage: UIImage? {
        if let data = imageData {
            return UIImage(data: data)
        } else {
            return nil
        }
    }
    
    // image to display
    func getThumbnailImage(completion: @escaping(_ image: UIImage?)->Void) {
        DispatchQueue.global(qos: .background).async {
            
            let storageRef = Storage.storage()
            
            let imageRef = storageRef.reference(forURL: self.thumbnail)
            
            imageRef.getData(maxSize: 2 * 1024 * 1024, completion: { (data, error) in
                if let error = error {
                    print("~>There was an error: \(error)")
                    completion(nil)
                    return
                }
                
                guard let realData = data else {
                    completion(nil)
                    return
                }
                
                self.imageData = realData
                completion(UIImage(data: realData))
                return
                
            })
        }
        
        
    }
    
}
