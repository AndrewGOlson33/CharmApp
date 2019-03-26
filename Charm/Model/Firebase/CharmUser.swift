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
    var trainingData: TrainingHistory?
    
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

// Training History

struct TrainingHistory: Codable {
    var concreteAverage: ConcreteTrainingHistory
    var sandboxHistory: SandboxTrainingHistory?
    
    init() {
        concreteAverage = ConcreteTrainingHistory()
    }
}

struct ConcreteTrainingHistory: Codable {
    var numQuestions: Int = 0
    var numCorrect: Int = 0
    
    var doubleNumQuestions: Double {
        return Double(numQuestions)
    }
    
    var doubleNumCorrect: Double {
        return Double(numCorrect)
    }
    
    // computed vars
    var numWrong: Int {
        return numQuestions - numCorrect
    }
    
    var averageScore: Double {
        return numQuestions == 0 ? 0.0 : Double(doubleNumCorrect / doubleNumQuestions)
    }
    
    var scoreValue: Double {
        return ceil(averageScore*100)/100
    }
}

struct SandboxTrainingHistory: Codable {
    
    var history: [SandboxScore] = []
    
    var average: SandboxAverage {
        let count: Double = Double(history.count)
        let length = (Double(history.map{$0.length}.reduce(0, +)) / count).rounded()
        let concrete = (Double(history.map{$0.concrete}.reduce(0, +)) / count).rounded()
        let abstract = (Double(history.map{$0.abstract}.reduce(0, +)) / count).rounded()
        let unclassified = (Double(history.map{$0.unclassified}.reduce(0, +)) / count).rounded()
        let first = (Double(history.map{$0.first}.reduce(0, +)) / count).rounded()
        let second = (Double(history.map{$0.second}.reduce(0, +)) / count).rounded()
        let positive = (Double(history.map{$0.positive}.reduce(0, +)) / count).rounded()
        let negative = (Double(history.map{$0.negative}.reduce(0, +)) / count).rounded()
        let repeated = (Double(history.map{$0.repeated}.reduce(0, +)) / count).rounded()
        
        return SandboxAverage(length: length, concrete: concrete, abstract: abstract, unclassified: unclassified, first: first, second: second, positive: positive, negative: negative, repeated: repeated)
    }
    
    mutating func append(_ score: SandboxScore) {
        if history.count >= 10 { history.removeFirst() }
        history.append(score)
        
        // upload new history to firebase
        do {
            let data = try FirebaseEncoder().encode(self)
            Database.database().reference().child(FirebaseStructure.Users).child(Auth.auth().currentUser!.uid).child(FirebaseStructure.Training.TrainingDatabase).child(FirebaseStructure.Training.SandboxHistory).setValue(data)
        } catch let error {
            print("~>There was an error converting the data into firebase format: \(error)")
        }
    }
    
}

struct SandboxAverage {
    var length: Double
    var concrete: Double
    var abstract: Double
    var unclassified: Double
    var first: Double
    var second: Double
    var positive: Double
    var negative: Double
    var repeated: Double
    
    init(length: Double, concrete: Double, abstract: Double, unclassified: Double, first: Double, second: Double, positive: Double, negative: Double, repeated: Double) {
        self.length = length
        self.concrete = concrete
        self.abstract = abstract
        self.unclassified = unclassified
        self.first = first
        self.second = second
        self.positive = positive
        self.negative = negative
        self.repeated = repeated
    }
}

struct SandboxScore: Codable {
    
    var length: Int
    var concrete: Int
    var abstract: Int
    var unclassified: Int
    var first: Int
    var second: Int
    var positive: Int
    var negative: Int
    var repeated: Int
    
    init(length: Int, concrete: Int, abstract: Int, unclassified: Int, first: Int, second: Int, positive: Int, negative: Int, repeated: Int) {
        self.length = length
        self.concrete = concrete
        self.abstract = abstract
        self.unclassified = unclassified
        self.first = first
        self.second = second
        self.positive = positive
        self.negative = negative
        self.repeated = repeated
    }
    
}
