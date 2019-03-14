//
//  Constants.swift
//  Charm
//
//  Created by Daniel Pratt on 3/6/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import Foundation

// MARK: - Server location constants

enum Server {
    static let BaseURL = "https://charmtokens.herokuapp.com"
    static let Room = "/room"
    static let Archive = "/archive"
    static let StartArchive = "/start"
    static let StopArchive = "/stop"
}

// MARK: - UI Related
enum SegueID {
    static let FriendList = "sid_friendlist"
    static let VideoCall = "sid_videocall"
}

enum StoryboardID {
    static let NavigationHome = "vc_navhome"
    static let VideoCall = "vc_videocall"
}

enum CellID {
    static let FriendList = "cid_friendlist"
    static let ChatList = "cid_chatlist"
    static let VideoList = "cid_video"
}

// MARK: - Firebase Related

enum FirebaseStructure {
    static let Users = "testUsers"
    
    enum CharmUser {
        static let ID = "id"
        
        // profile
        static let Profile = "userProfile" // base
        
        enum UserProfile {
            static let Email = "email"
            static let FirstName = "firstName"
            static let LastName = "lastName"
            static let MembershipStatus = "membershipStatus"
            static let NumCredits = "numCredits"
            static let RenewDate = "renewDate"
        }
        
        // friends
        static let Friends = "friendList" // base
        enum FriendList {
            static let CurrentFriends = "currentFriends"
            static let PendingSentApproval = "pendingSentApproval"
            static let PendingReceivedApproval = "pendingReceivedApproval"
        }
        
        // calls
        static let Call = "currentCall"
        enum CurrentCall {
            static let SessionID = "sessionID"
            static let CallStatus = "status"
        }
        
    }
    
    enum Friend {
        static let ID = "id"
        static let FirstName = "firstName"
        static let LastName = "lastName"
        static let Email = "email"
    }
    
    // Archives
    enum Archive {
        static let Pending = "pendingArchive"
        static let Completed = "completedArchive"
        
        enum ArchiveData {
            static let SessionId = "sessionId"
            static let InitiatingUserId = "initiatingUserId"
            static let ReceivingUserId = "receivingUserId"
        }
    }
    
    // Learning Videos
    enum Videos {
        static let Learning = "learning"
        
        enum Sections {
            static let Fundamentals = "Fundamentals"
            static let Supplemental = "Supplemental"
        }
        
        enum VideoItem {
            static let Title = "title"
            static let Url = "url"
        }
    }
    
    
}

// MARK: - Notifications

enum FirebaseNotification {
    static let CharmUserDidUpdate = Notification.Name("notificationCharmUserDidUpdate")
    static let CharmUserIncomingCall = Notification.Name("notificationCharmUserHasIncomingCall")
}
