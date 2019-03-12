//
//  Protocols.swift
//  Charm
//
//  Created by Daniel Pratt on 3/6/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import Foundation

// MARK: - Protocols

// Use for Firebase Objects that need to have the uid stored in model
protocol Identifiable {
    var id: String? { get set }
}

// MARK: - Delegates

// Delegate that handles approving friend requests
protocol FriendManagementDelegate {
    func approveFriendRequest(withId id: String)
    func sendEmailRequest(toFriend friend: Friend)
}

// Delegate that allows a view model to update table view
protocol TableViewRefreshDelegate {
    func updateTableView()
}
