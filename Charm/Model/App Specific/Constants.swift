//
//  Constants.swift
//  Charm
//
//  Created by Daniel Pratt on 3/6/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import Foundation

// MARK: - UI Related
enum SegueID {
    static let FriendList = "sid_friendlist"
    static let VideoCall = "sid_videocall"
}

enum StoryboardID {
    static let NavigationHome = "vc_navhome"
}

enum CellID {
    static let FriendList = "cid_friendlist"
}

// MARK: - Firebase Related

enum FirebaseStructure {
    static let Users = "testUsers"
    
    enum CharmUser {
        static let ID = "id"
        static let Profile = "userProfile"
        enum UserProfile {
            static let Email = "email"
            static let FirstName = "firstName"
            static let LastName = "lastName"
            static let MembershipStatus = "membershipStatus"
            static let NumCredits = "numCredits"
            static let RenewDate = "renewDate"
        }
        static let Friends = "friendList"
        enum FriendList {
            static let CurrentFriends = "currentFriends"
            static let PendingSentApproval = "pendingSentApproval"
            static let PendingReceivedApproval = "pendingReceivedApproval"
        }
    }
    
    enum Friend {
        static let ID = "id"
        static let FirstName = "firstName"
        static let LastName = "lastName"
        static let Email = "email"
    }
}

// MARK: - Notifications

enum FirebaseNotification {
    static let CharmUserDidUpdate = Notification.Name("notificationCharmUserDidUpdate")
}
