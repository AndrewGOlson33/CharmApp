//
//  TestModel.swift
//  Charm
//
//  Created by Daniel Pratt on 3/6/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import Foundation
import Firebase

enum FirebaseItemError: Error {
    case noSnapshot
    case invalidData
    case invalidParameter
}

struct  CharmUser: FirebaseItem {
       
    var id: String? = nil
    var ref: DatabaseReference?
    var userProfile: UserProfile
    var friendList: FriendList?
    var trainingData: TrainingHistory
    var tokenID: [String : Bool]? = nil
    
    // Init to create a new user
    init(name: String, email: String) {
        userProfile = UserProfile(name: name, email: email)
        friendList = FriendList()
        trainingData = try! TrainingHistory()
    }
    
    init(snapshot: DataSnapshot) throws {
        guard let topValues = snapshot.value as? [String : Any] else {
            throw FirebaseItemError.invalidData
        }
        
        let profileSnapshot = snapshot.childSnapshot(forPath: FirebaseStructure.CharmUser.profileLocation)
        let friendListSnapshot = snapshot.childSnapshot(forPath: FirebaseStructure.CharmUser.friendListLocation)
        let trainingSnapshot = snapshot.childSnapshot(forPath: FirebaseStructure.Training.trainingDatabase)
        id = snapshot.key
        ref = snapshot.ref
        do {
            userProfile = try UserProfile(snapshot: profileSnapshot)
            friendList = try FriendList(snapshot: friendListSnapshot)
            trainingData = try TrainingHistory(snapshot: trainingSnapshot)
        } catch {
            throw FirebaseItemError.invalidData
        }
        
        tokenID = topValues[FirebaseStructure.CharmUser.token] as? [String : Bool]
    }
    
    func toAny() -> [AnyHashable:Any] {
        return [
            FirebaseStructure.CharmUser.profileLocation : userProfile.toAny()
        ]
    }
    
    func save() {
        userProfile.save()
        friendList?.save()
        trainingData.save()
    }
    
}


// User Profile

struct UserProfile: FirebaseItem {
    
    enum MembershipStatus: Int, Codable {
        case unknown = 0
        case notSubscribed = 1
        case currentSubscriber = 2
        case formerSubscriber = 3
    }
    
    var id: String?
    var ref: DatabaseReference?
    var firstName: String
    var lastName: String
    var email: String
    var phone: String
    var numCredits: Int
    var renewDate: Date
    var membershipStatus: MembershipStatus
    
    // Calculated Variables
    
    var credits: String {
        return "\(numCredits)"
    }
    
    var renewDateString: String {
        let dFormatter = DateFormatter()
        dFormatter.dateStyle = .short
        return dFormatter.string(from: renewDate)
    }
    
    init(name: String, email: String, phone: String = "") {
        
        let userName = UserProfile.getFirstLast(from: name)
        firstName = userName.first
        lastName = userName.last
        self.email = email
        numCredits = 3
        renewDate = Date()
        membershipStatus = .unknown
        self.phone = phone
    }
    
    init(snapshot: DataSnapshot) throws {
        guard let values = snapshot.value as? [String:Any] else {
            throw FirebaseItemError.invalidData
        }
        
        id = snapshot.key
        ref = snapshot.ref
        
        firstName = values[FirebaseStructure.CharmUser.UserProfile.firstName] as? String ?? ""
        lastName = values[FirebaseStructure.CharmUser.UserProfile.lastName] as? String ?? ""
        email = values[FirebaseStructure.CharmUser.UserProfile.email] as? String ?? ""
        numCredits = values[FirebaseStructure.CharmUser.UserProfile.numCredits] as? Int ?? 0
        phone = values[FirebaseStructure.CharmUser.UserProfile.phone] as? String ?? ""
        let timeSinceReferenceDate = values[FirebaseStructure.CharmUser.UserProfile.renewDate] as? Double ?? -1.0
        let membershipStatusRawValue = values[FirebaseStructure.CharmUser.UserProfile.membershipStatus] as? Int ?? 0
        
        renewDate = timeSinceReferenceDate == -1 ? Date() : Date(timeIntervalSinceReferenceDate: timeSinceReferenceDate)
        membershipStatus = MembershipStatus(rawValue: membershipStatusRawValue) ?? .unknown
    }
    
    mutating func updateUser(name: String) {
        let current = firstName + " " + lastName
        print("~>Current: \(current) new: \(name)")
        if name == current { return }
        
        let names = UserProfile.getFirstLast(from: name)
        if names.first != "" {
            firstName = names.first
            lastName = names.last
            let data = self.toAny()
            
            DispatchQueue.global(qos: .utility).async {
                Database.database().reference().child(FirebaseStructure.usersLocation).child(Auth.auth().currentUser!.uid).child(FirebaseStructure.CharmUser.profileLocation).setValue(data)
            }
        }
        
        
    }
    
    private static func getFirstLast(from name: String) -> (first: String, last: String) {
        let names = name.components(separatedBy: " ")
        guard names.count > 0 else { return (first: "", last: "") }
        var first = ""
        var last = ""
        if let firstName = names.first { first = firstName }
        if names.count > 1, let lastName = names.last { last = lastName }
        
        return (first: first, last: last)
    }
    
    func toAny() -> [AnyHashable:Any] {
        return [
            FirebaseStructure.CharmUser.UserProfile.firstName : firstName as NSString,
            FirebaseStructure.CharmUser.UserProfile.lastName : lastName as NSString,
            FirebaseStructure.CharmUser.UserProfile.email : email as NSString,
            FirebaseStructure.CharmUser.UserProfile.phone : phone as NSString,
            FirebaseStructure.CharmUser.UserProfile.numCredits : numCredits as NSNumber,
            FirebaseStructure.CharmUser.UserProfile.renewDate : renewDate.timeIntervalSinceReferenceDate as NSNumber,
            FirebaseStructure.CharmUser.UserProfile.membershipStatus : membershipStatus.rawValue as NSNumber
        ]
    }

}

// Call

struct Call: FirebaseItem {
    
    enum CallStatus: Int {
        case connected = 0
        case disconnected = 1
        case incoming = 2
        case outgoing = 3
        case rejected = 4
        case unknown = 5
    }
    
    var id: String?
    var ref: DatabaseReference?
    var sessionID: String
    var status: CallStatus
    var fromUserID: String
    var room: String
    
    var myCallRef: DatabaseReference {
        return Database.database().reference().child(FirebaseStructure.usersLocation).child(Auth.auth().currentUser!.uid).child(FirebaseStructure.CharmUser.currentCallLocation)
    }
    
    var friendCallRef: DatabaseReference {
        return Database.database().reference().child(FirebaseStructure.usersLocation).child(fromUserID).child(FirebaseStructure.CharmUser.currentCallLocation)
    }
    
    init(snapshot: DataSnapshot) throws {
        guard let values = snapshot.value as? [String:Any] else { throw FirebaseItemError.invalidData }
        id = snapshot.key
        ref = snapshot.ref
        
        sessionID = values[FirebaseStructure.CharmUser.CurrentCall.sessionID] as? String ?? ""
        let statusInt = values[FirebaseStructure.CharmUser.CurrentCall.callStatus] as? Int ?? 5
        status = CallStatus(rawValue: statusInt) ?? .unknown
        fromUserID = values[FirebaseStructure.CharmUser.CurrentCall.from] as? String ?? ""
        room = values[FirebaseStructure.CharmUser.CurrentCall.room] as? String ?? ""
    }
    
    init(sessionID: String, status: CallStatus, from: String, in room: String) {
        self.sessionID = sessionID
        self.status = status
        self.fromUserID = from
        self.room = room
    }
    
    func toAny() -> [AnyHashable : Any] {
        return [
            FirebaseStructure.CharmUser.CurrentCall.sessionID : sessionID as NSString,
            FirebaseStructure.CharmUser.CurrentCall.callStatus : status.rawValue as NSNumber,
            FirebaseStructure.CharmUser.CurrentCall.from : fromUserID as NSString,
            FirebaseStructure.CharmUser.CurrentCall.room : room as NSString
        ]
    }
}

// Friends List

struct FriendList: FirebaseItem {
    var id: String?
    var ref: DatabaseReference?
    
    init() {
    }
    
    init(currentFriends: [Friend], pendingSentApproval: [Friend], pendingReceivedApproval: [Friend], sentText: [Friend]) {
        self.currentFriends = currentFriends
        self.pendingSentApproval = pendingSentApproval
        self.pendingReceivedApproval = pendingReceivedApproval
        self.sentText = sentText
    }
    
    init(snapshot: DataSnapshot) throws {
        let currentFriendsSS = snapshot.childSnapshot(forPath: FirebaseStructure.CharmUser.FriendList.currentFriends)
        let pendngSentSS = snapshot.childSnapshot(forPath: FirebaseStructure.CharmUser.FriendList.pendingSentApproval)
        let pendngReceivedSS = snapshot.childSnapshot(forPath: FirebaseStructure.CharmUser.FriendList.pendingReceivedApproval)
        let sentTextSS = snapshot.childSnapshot(forPath: FirebaseStructure.CharmUser.FriendList.sentText)
        
        id = snapshot.key
        ref = snapshot.ref
        
        if currentFriends == nil { currentFriends = [] }
        if pendingSentApproval == nil { pendingSentApproval = [] }
        if pendingReceivedApproval == nil { pendingReceivedApproval = [] }
        if sentText == nil { sentText = [] }
        
        if currentFriendsSS.exists() {
            for child in currentFriendsSS.children {
                if let childSnap = child as? DataSnapshot {
                    do {
                        let friend = try Friend(snapshot: childSnap)
                        if !currentFriends!.contains(where: { (existing) -> Bool in
                            friend.id == existing.id
                        }) {
                            currentFriends?.append(friend)
                        }
                    } catch let error {
                        print("~>Got an error trying to convert: \(error)")
                    }
                   
                }
            }
        }
        
        if pendngSentSS.exists() {
            for child in pendngSentSS.children {
                if let childSnap = child as? DataSnapshot {
                    do {
                        let friend = try Friend(snapshot: childSnap)
                        if !pendingSentApproval!.contains(where: { (existing) -> Bool in
                            friend.id == existing.id
                        }) {
                            pendingSentApproval?.append(friend)
                        }
                    } catch let error {
                        print("~>Got an error trying to convert: \(error)")
                    }
                   
                }
            }
        }
        
        if pendngReceivedSS.exists() {
            for child in pendngReceivedSS.children {
                if let childSnap = child as? DataSnapshot {
                    do {
                        let friend = try Friend(snapshot: childSnap)
                        if !pendingReceivedApproval!.contains(where: { (existing) -> Bool in
                            friend.id == existing.id
                        }) {
                            pendingReceivedApproval?.append(friend)
                        }
                    } catch let error {
                        print("~>Got an error trying to convert: \(error)")
                    }
                   
                }
            }
        }
        
        if sentTextSS.exists() {
            for child in sentTextSS.children {
                if let childSnap = child as? DataSnapshot {
                    do {
                        let friend = try Friend(snapshot: childSnap)
                        if !sentText!.contains(where: { (existing) -> Bool in
                            friend.id == existing.id
                        }) {
                            sentText?.append(friend)
                        }
                    } catch let error {
                        print("~>Got an error trying to convert: \(error)")
                    }
                   
                }
            }
        }
    }
    
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
    
    var sentText: [Friend]? = [] {
        didSet {
            sentText?.sort(by: { (lhs, rhs) -> Bool in
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
    
    func toAny() -> [AnyHashable : Any] {

        // save via save function, not toAny
        return [:]
    }
    
    func save() {
        for var friend in currentFriends ?? [] {
            if let fID = friend.friendId, !fID.isEmpty, fID != friend.id {
                if let ref = friend.ref { ref.removeValue() }
                let friendRef = ref?.child(FirebaseStructure.CharmUser.FriendList.currentFriends).child(fID)
                friend.friendId = friendRef?.key
                friend.id = friendRef?.key
                friend.ref = friendRef
            }
            
            friend.save()
        }
        
        for var friend in pendingSentApproval ?? [] {
            if let fID = friend.friendId, !fID.isEmpty, fID != friend.id  {
                if let ref = friend.ref { ref.removeValue() }
                let friendRef = ref?.child(FirebaseStructure.CharmUser.FriendList.pendingSentApproval).child(fID)
                friend.friendId = friendRef?.key
                friend.id = friendRef?.key
                friend.ref = friendRef
            }
            
            friend.save()
        }
        
        for var friend in pendingReceivedApproval ?? [] {
            if let fID = friend.friendId, !fID.isEmpty, fID != friend.id  {
                if let ref = friend.ref { ref.removeValue() }
                let friendRef = ref?.child(FirebaseStructure.CharmUser.FriendList.pendingReceivedApproval).child(fID)
                friend.friendId = friendRef?.key
                friend.id = friendRef?.key
                friend.ref = friendRef
            }
            
            friend.save()
        }
        
        for var friend in sentText ?? [] {
            if let fID = friend.friendId, !fID.isEmpty, (fID != friend.id || fID == "N/A")  {
                if let ref = friend.ref { ref.removeValue() }
                let friendRef = ref?.child(FirebaseStructure.CharmUser.FriendList.sentText).childByAutoId()
                friend.friendId = friendRef?.key
                friend.id = friendRef?.key
                friend.ref = friendRef
            }
            
            friend.save()
        }
    }
}

// Friend Info

struct Friend: FirebaseItem {
    
    var id: String? = nil
    var ref: DatabaseReference?
    var friendId: String? = nil
    var firstName: String
    var lastName: String
    var email: String
    var phone: String
    
    init(id: String, first: String, last: String, email: String, phone: String = "") {
        self.id = id
        firstName = first
        friendId = id
        lastName = last
        self.email = email
        self.phone = phone
    }
    
    init(snapshot: DataSnapshot) throws {
        guard let values = snapshot.value as? [String : Any] else {
            throw FirebaseItemError.invalidData
        }
        
        id = snapshot.key
        ref = snapshot.ref
        
        firstName = values[FirebaseStructure.Friend.firstName] as? String ?? ""
        lastName = values[FirebaseStructure.Friend.lastName] as? String ?? ""
        email = values[FirebaseStructure.Friend.email] as? String ?? ""
        phone = values[FirebaseStructure.Friend.phone] as? String ?? ""
        friendId = values[FirebaseStructure.Friend.id] as? String ?? ""
    }
    
    func toAny() -> [AnyHashable : Any] {
        let id: String
        if let fID = friendId { id = fID } else { id = "" }
        return [
            FirebaseStructure.Friend.firstName : firstName as NSString,
            FirebaseStructure.Friend.lastName : lastName as NSString,
            FirebaseStructure.Friend.email : email as NSString,
            FirebaseStructure.Friend.phone : phone as NSString,
            FirebaseStructure.Friend.id : id as NSString
        ]
    }

}

// Training History

struct TrainingHistory: FirebaseItem {
    
    var id: String?
    var ref: DatabaseReference?
    var conversationLevel: TrainingLevel
    var concreteAverage: TrainingStatistics
    var emotionsAverage: TrainingStatistics
    
    init() throws {
        guard let uid = FirebaseModel.shared.charmUser.id else { throw FirebaseItemError.invalidParameter }
        conversationLevel = TrainingLevel()
        concreteAverage = TrainingStatistics()
        emotionsAverage = TrainingStatistics()
        
        ref = Database.database().reference().child(FirebaseStructure.usersLocation).child(uid).child(FirebaseStructure.Training.trainingDatabase)
        id = ref?.key
        self.save()
    }
    
    init(snapshot: DataSnapshot) throws {
        id = snapshot.key
        ref = snapshot.ref
        
        let conversationSnap = snapshot.childSnapshot(forPath: FirebaseStructure.Training.conversationLevel)
        let concreteSnap = snapshot.childSnapshot(forPath: FirebaseStructure.Training.concreteHistory)
        let emotionsSnap = snapshot.childSnapshot(forPath: FirebaseStructure.Training.emotionHistory)
        
        var shouldSave: Bool = false
        
        if conversationSnap.exists() {
            do {
                conversationLevel = try TrainingLevel(snapshot: conversationSnap)
            } catch {
                conversationLevel = TrainingLevel()
            }
        } else { conversationLevel = TrainingLevel(); shouldSave = true }
        
        if concreteSnap.exists() {
            do {
                concreteAverage = try TrainingStatistics(snapshot: concreteSnap)
            } catch {
                concreteAverage = TrainingStatistics()
            }
        } else { concreteAverage = TrainingStatistics(); shouldSave = true }
        
        if emotionsSnap.exists() {
            do {
                emotionsAverage = try TrainingStatistics(snapshot: emotionsSnap)
            } catch {
                emotionsAverage = TrainingStatistics()
            }
        } else { emotionsAverage = TrainingStatistics(); shouldSave = true }
        
        if shouldSave {
            self.save()
        }
    }
    
    func toAny() -> [AnyHashable : Any] {
        return [
            FirebaseStructure.Training.conversationLevel : conversationLevel.toAny(),
            FirebaseStructure.Training.concreteHistory : concreteAverage.toAny(),
            FirebaseStructure.Training.emotionHistory : emotionsAverage.toAny()
        ]
    }
    
}

struct TrainingLevel: FirebaseItem {
    var id: String?
    var ref: DatabaseReference?
    
    var experience: Int {
        didSet {
            if experience >= nextLevelXP { currentLevel += 1 }
            date = Date().timeIntervalSince1970
            save()
        }
    }
    
    private var date: Double
    
    var lastTrained: Date {
        return Date(timeIntervalSince1970: date)
    }
    
    var currentLevel: Int = 1
    var levelDetail: String {
        switch currentLevel {
        case 1...6:
            return "Level \(currentLevel): Novice"
        case 7...16:
            return "Level \(currentLevel): Beginner"
        case 17...22:
            return "Level \(currentLevel): Advanced"
        case 23...30:
            return "Level \(currentLevel): Ninja"
        default:
            return "Level \(currentLevel): Ninja Master"
        }
    }
    
    
    var nextLevelXP: Int {
        return calculateExperience(forLevel: currentLevel)
    }
    
    var progress: Double {
        let thisLevel: Int = currentLevel == 1 ? 0 : calculateExperience(forLevel: currentLevel - 1)
        let nextLevel: Int = calculateExperience(forLevel: currentLevel)
        let difference: Double = Double(nextLevel - thisLevel)
        let progress: Double = Double(experience - thisLevel)
        
        return progress / difference
    }
    
    init(snapshot: DataSnapshot) throws {
        guard let values = snapshot.value as? [String:Any] else { throw FirebaseItemError.invalidData }
        id = snapshot.key
        ref = snapshot.ref
        
        experience = values[FirebaseStructure.Training.Level.experience] as? Int ?? 0
        date = values[FirebaseStructure.Training.Level.lastTrainedDate] as? Double ?? Date().timeIntervalSince1970
    }
    
    init() {
        experience = 0
        date = Date().timeIntervalSince1970
    }
    
    mutating func add(experience: Int) {
        self.experience += experience
    }
    
    fileprivate func calculateExperience(forLevel level: Int) -> Int {
        let lvl = Double(level) + 0.75
        return Int((log(lvl * lvl) * log(lvl * lvl)) * 25)
    }
    
    func toAny() -> [AnyHashable : Any] {
        return [
            FirebaseStructure.Training.Level.experience : experience,
            FirebaseStructure.Training.Level.lastTrainedDate : lastTrained.timeIntervalSince1970
        ]
    }

}

struct TrainingStatistics: FirebaseItem {
    
    var id: String?
    var ref: DatabaseReference?
    var numQuestions: Int = 0
    var numCorrect: Int = 0
    var correctRecord: Int = 1
    
    // computed vars
    var doubleNumQuestions: Double {
        return Double(numQuestions)
    }
    
    var doubleNumCorrect: Double {
        return Double(numCorrect)
    }
    
    var percentOfRecord: Double {
        return Double(numCorrect) / Double(correctRecord)
    }
    
    var numWrong: Int {
        return numQuestions - numCorrect
    }
    
    var averageScore: Double {
        return numQuestions == 0 ? 0.0 : Double(doubleNumCorrect / doubleNumQuestions)
    }
    
    var scoreValue: Double {
        return ceil(averageScore*100)/100
    }
    
    var currentStreakDetail: String {
        return "Current Streak: \(numCorrect)"
    }
    
    var highScoreDetail: String {
        return "High Score: \(highScore)"
    }
    
    var highScore: Int {
        return correctRecord
    }
    
    init(snapshot: DataSnapshot) throws {
        guard let values = snapshot.value as? [String:Any] else { throw FirebaseItemError.invalidData }
        id = snapshot.key
        ref = snapshot.ref
        numQuestions = values[FirebaseStructure.Training.Stats.numQuestions] as? Int ?? 0
        numCorrect = values[FirebaseStructure.Training.Stats.numCorrect] as? Int ?? 0
        correctRecord = values[FirebaseStructure.Training.Stats.correctRecord] as? Int ?? 0
    }
    
    init() {
        numQuestions = 0
        numCorrect = 0
        correctRecord = 1
    }
    
    func toAny() -> [AnyHashable : Any] {
        return [
            FirebaseStructure.Training.Stats.numQuestions : numQuestions as NSNumber,
            FirebaseStructure.Training.Stats.numCorrect : numCorrect as NSNumber,
            FirebaseStructure.Training.Stats.correctRecord : correctRecord as NSNumber
        ]
    }
}
