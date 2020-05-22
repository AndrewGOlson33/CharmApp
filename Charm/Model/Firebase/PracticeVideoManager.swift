//
//  PracticeVideoManager.swift
//  Charm
//
//  Created by Игорь on 16.0520..
//  Copyright © 2020 Charm, LLC. All rights reserved.
//

import Foundation
import Firebase

class PracticeVideoManager {
    
    static let shared = PracticeVideoManager()
    static let storageKey = "practice"
    
    // MARK: - Properties
    
    var storageReference = Storage.storage().reference()
    
    var partners: [PracticePartner] = []
    
    // MARK: - Methods
    
    func getListOfFiles() {
        guard let _ = FirebaseModel.shared.charmUser.id else {
            NotificationCenter.default.post(name: FirebaseNotification.didFailToUpdatePracticeVideos, object: nil)
            return
        }
        
        storageReference.child(PracticeVideoManager.storageKey).listAll { (result, error) in
            if let error = error {
                NotificationCenter.default.post(name: FirebaseNotification.didFailToUpdatePracticeVideos, object: nil)
                print(error.localizedDescription)
                return
            }
            
            let storageURL: String = "https://firebasestorage.googleapis.com/v0/b/charismaanalytics-57703.appspot.com/o/"
            
            var partners: [String : [PracticeVideo]] = [:]
            for item in result.items {
                
                let newURLString = storageURL + item.fullPath.replacingOccurrences(of: "/", with: "%2F")
                let videoName = item.fullPath.replacingOccurrences(of:"\(PracticeVideoManager.storageKey)/", with: "")
                let pieces = videoName.split(separator: "_")
                if pieces.count > 2 {
                    if var url = URL(string: newURLString), let partner = pieces.first {
                        let videoID = String(pieces[1])
                        if let type = PracticeVideo.PracticeVideoType(rawValue: String(pieces[2].first ?? "N")) {
                            url.appending("alt", value: "media")
                            let video = PracticeVideo(id: videoID, type: type, url: url)
                            var videos = partners[String(partner)] ?? []
                            videos.append(video)
                            partners.updateValue(videos, forKey: String(partner))
                        }
                    }
                }
            }
            
            for partner in partners {
                let newPartner = PracticePartner(name: partner.key, videos: partner.value)
                self.partners.append(newPartner)
            }
             NotificationCenter.default.post(name: FirebaseNotification.didUpdatePracticeVideos, object: nil)
        }
    }
    
    
    
    //
    
}
