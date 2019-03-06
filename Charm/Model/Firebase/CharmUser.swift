//
//  TestModel.swift
//  Charm
//
//  Created by Daniel Pratt on 3/6/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import Foundation
import CodableFirebase

struct CharmUser: Codable, Identifiable {
    
    var id: String? = nil
    var userProfile: UserProfile
    
    init(first: String, last: String, email: String) {
        userProfile = UserProfile(first: first, last: last, email: email)
    }
    
}

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
