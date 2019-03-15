//
//  TestModel.swift
//  Charm
//
//  Created by Daniel Pratt on 3/6/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import Foundation
import Firebase
import CodableFirebase

struct CharmUser: Codable, Identifiable {
    
    var id: String? = nil
    var userProfile: UserProfile
    var friendList: FriendList?
    var currentCall: Call?
    
    init(first: String, last: String, email: String) {
        userProfile = UserProfile(first: first, last: last, email: email)
        friendList = FriendList()
    }
    
}

// User Profile

struct UserProfile: Codable {
    enum MembershipStatus: Int, Codable {
        case unknown = 1
    }
    
    var firstName: String
    var lastName: String
    var email: String
    var numCredits: Int
    var renewDate: Date
    var membershipStatus: MembershipStatus
    
    init(first: String, last: String, email: String) {
        firstName = first
        lastName = last
        self.email = email
        numCredits = 10
        renewDate = Date()
        membershipStatus = .unknown
    }
}

// Call

struct Call: Codable {
    enum CallStatus: Int, Codable {
        case connected = 0
        case disconnected = 1
        case incoming = 2
        case outgoing = 3
        case rejected = 4
    }
    
    var sessionID: String
    var status: CallStatus
    var fromUserID: String
    
    var myCallRef: DatabaseReference {
        return Database.database().reference().child(FirebaseStructure.Users).child(Auth.auth().currentUser!.uid).child(FirebaseStructure.CharmUser.Call)
    }
    
    var friendCallRef: DatabaseReference {
        return Database.database().reference().child(FirebaseStructure.Users).child(fromUserID).child(FirebaseStructure.CharmUser.Call)
    }
    
    init(sessionID: String, status: CallStatus, from: String) {
        self.sessionID = sessionID
        self.status = status
        self.fromUserID = from
    }
}

// Friends List

struct FriendList: Codable {
    var currentFriends: [Friend]? = [] {
        didSet {
            currentFriends?.sort(by: { (lhs, rhs) -> Bool in
                return lhs.lastName < rhs.lastName
            })
        }
    }
    var pendingSentApproval: [Friend]? = [] {
        didSet {
            pendingSentApproval?.sort(by: { (lhs, rhs) -> Bool in
                return lhs.lastName < rhs.lastName
            })
        }
    }
    var pendingReceivedApproval: [Friend]? = [] {
        didSet {
            pendingReceivedApproval?.sort(by: { (lhs, rhs) -> Bool in
                return lhs.lastName < rhs.lastName
            })
        }
    }
    
    var count: Int {
        var count = 0
        if let current = currentFriends { count += current.count }
        if let pendingSent = pendingSentApproval { count += pendingSent.count }
        if let pendingReceived = pendingReceivedApproval { count += pendingReceived.count }
        return count
    }
}

// Friend Info

struct Friend: Codable, Identifiable {
    var id: String? = nil
    var firstName: String
    var lastName: String
    var email: String
    var phone: String? = nil
    
    init(id: String, first: String, last: String, email: String) {
        self.id = id
        firstName = first
        lastName = last
        self.email = email
    }
}
