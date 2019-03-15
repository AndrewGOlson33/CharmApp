//
//  ArchiveSession.swift
//  Charm
//
//  Created by Daniel Pratt on 3/13/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import Foundation
import CodableFirebase
import Firebase

struct SessionArchive: Codable, Identifiable {
    
    var id: String? = nil
    var initiatingUserId: String
    var receivingUserId: String
    
    init(id: String, callerId: String, calledId: String) {
        self.id = id
        initiatingUserId = callerId
        receivingUserId = calledId
    }
    
    func addPending() -> Bool {
        guard let id = self.id else { return false }
        do {
            let data = try FirebaseEncoder().encode(self)
            Database.database().reference().child(FirebaseStructure.Archive.Pending).child(id).setValue(data)
        return true
        } catch let error {
            print("~>Got an error trying to add pending: \(error)")
            return false
        }
    }
    
    func removePending() -> Bool {
        guard let id = self.id else { return false }
        Database.database().reference().child(FirebaseStructure.Archive.Pending).child(id).removeValue()
        return true
    }
    
}
