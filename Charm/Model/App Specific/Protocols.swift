//
//  Protocols.swift
//  Charm
//
//  Created by Daniel Pratt on 3/6/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import Foundation
import Firebase

// MARK: - Protocols

// Use for Firebase Objects that need to have the uid stored in model
protocol FirebaseItem {
    var id: String? { get set }
    var ref: DatabaseReference? { get }
    
    init(snapshot: DataSnapshot) throws
    func toAny() -> [AnyHashable : Any]
    func save()
}

extension FirebaseItem {
    func save() {
        guard let ref = ref else { return }
        ref.setValue(self.toAny())
    }
}

// MARK: - Delegates

// Delegate that handles approving friend requests
protocol FriendManagementDelegate {
    func approveFriendRequest(withId id: String)
    func sendEmailRequest(toFriend friend: Friend)
    func sendTextRequest(toFriend friend: Friend)
}

// Delegate that allows a view model to update table view
protocol TableViewRefreshDelegate {
    func updateTableView()
}

// Delegate that sends setup info back to sign in screen
protocol NewUserDelegate {
    func createUser(withEmail email: String, password: String, firstName: String, lastName: String)
}
