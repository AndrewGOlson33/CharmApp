//
//  LearningVideo.swift
//  Charm
//
//  Created by Daniel Pratt on 3/14/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import Foundation
import Firebase

struct VideoSections: FirebaseItem {
    var id: String?
    var ref: DatabaseReference?
    var sections: [VideoSection] = []
    
    init(snapshot: DataSnapshot) throws {
        guard snapshot.exists() else { throw FirebaseItemError.noSnapshot }
        id = snapshot.key
        ref = snapshot.ref
        
        for child in snapshot.children {
            if let childSnap = child as? DataSnapshot {
                sections.append(try VideoSection(snapshot: childSnap))
            }
        }
    }
    
    // users cannot make changes
    func toAny() -> [AnyHashable : Any] {
        return [:]
    }
}

struct VideoSection: FirebaseItem {
    var id: String?
    var ref: DatabaseReference?
    var sectionTitle: String
    var videos: [LearningVideo] = []
    
    init(snapshot: DataSnapshot) throws {
        guard snapshot.exists() else { throw FirebaseItemError.noSnapshot }
        guard let values = snapshot.value as? [String:Any] else { throw FirebaseItemError.invalidData }
        let videosSnap = snapshot.childSnapshot(forPath: "videos")
        
        id = snapshot.key
        ref = snapshot.ref
        sectionTitle = values["sectionTitle"] as? String ?? ""
        
        for child in videosSnap.children {
            if let childSnap = child as? DataSnapshot {
                videos.append(try LearningVideo(snapshot: childSnap))
            }
        }
    }
    
    // users cannot make changes
    func toAny() -> [AnyHashable : Any] {
        return [:]
    }
}

class LearningVideo: FirebaseItem {
    var id: String?
    var ref: DatabaseReference?
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
    
    required init(snapshot: DataSnapshot) throws {
        guard snapshot.exists() else { throw FirebaseItemError.noSnapshot }
        guard let values = snapshot.value as? [String:Any] else { throw FirebaseItemError.invalidData }
        
        id = snapshot.key
        ref = snapshot.ref
        title = values["title"] as? String ?? ""
        url = values["url"] as? String ?? ""
        thumbnail = values["thumbnail"] as? String ?? ""
    }
    
    // users cannot make changes
    func toAny() -> [AnyHashable : Any] {
        return [:]
    }
    
    // image to display
    func getThumbnailImage(completion: @escaping(_ image: UIImage?)->Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            
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
