//
//  ArchiveSession.swift
//  Charm
//
//  Created by Daniel Pratt on 3/13/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import Foundation
import Firebase

struct SessionArchive: FirebaseItem {
    
    var id: String? = nil
    var ref: DatabaseReference?
    var initiatingUserId: String
    var initiatingUserFirstName: String
    var receivingUserId: String
    var receivingUserFirstName: String
    var archiveComplete: Bool = false
    
    init(id: String, callerId: String, calledId: String, callerName: String, calledName: String) {
        self.id = id
        ref = Database.database().reference().child(FirebaseStructure.Archive.pending).child(id)
        initiatingUserId = callerId
        initiatingUserFirstName = callerName
        receivingUserId = calledId
        receivingUserFirstName = calledName
        
        self.save()
    }
    
    init(snapshot: DataSnapshot) throws {
        guard snapshot.exists() else { throw FirebaseItemError.noSnapshot }
        guard let values = snapshot.value as? [String:Any] else { throw FirebaseItemError.invalidData }
        
        id = snapshot.key
        ref = snapshot.ref
        initiatingUserId = values["initiatingUserId"] as? String ?? ""
        initiatingUserFirstName = values["initiatingUserFirstName"] as? String ?? ""
        receivingUserId = values["receivingUserId"] as? String ?? ""
        receivingUserFirstName = values["receivingUserFirstName"] as? String ?? ""
        archiveComplete = values["archiveComplete"] as? Bool ?? false
    }
    
    func toAny() -> [AnyHashable : Any] {
        return [
            "initiatingUserId" : initiatingUserId as NSString,
            "initiatingUserFirstName" : initiatingUserFirstName as NSString,
            "receivingUserId" : receivingUserId as NSString,
            "receivingUserFirstName" : receivingUserFirstName as NSString,
            "archiveComplete" : archiveComplete
        ]
    }
    
//    func addPending() -> Bool {
//        guard let id = self.id else { return false }
//        do {
//            let data = try FirebaseEncoder().encode(self)
//            DispatchQueue.global(qos: .utility).async {
//                Database.database().reference().child(FirebaseStructure.Archive.pending).child(id).setValue(data)
//            }
//
//            return true
//        } catch let error {
//            print("~>Got an error trying to add pending: \(error)")
//            return false
//        }
//    }
    
    mutating func setArchiveComplete() {
        guard self.id != nil else { return }
        archiveComplete = true
        self.save()
    }
    
    func removePending() -> Bool {
        guard let ref = self.ref, self.id != nil else { return false }
        ref.removeValue()
        
        return true
    }
}
