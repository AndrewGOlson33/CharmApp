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
    static let DetailChart = "sid_detailchart"
    static let TrainingChart = "sid_trainingchart"
}

enum StoryboardID {
    static let NavigationHome = "vc_navhome"
    static let VideoCall = "vc_videocall"
    static let LabelPopover = "vc_labelpopover"
}

enum CellID {
    static let FriendList = "cid_friendlist"
    static let ChatList = "cid_chatlist"
    static let EmptyChatList = "cid_emptychatlist"
    static let VideoList = "cid_video"
    static let SummaryMetric = "cid_summary"
    static let ViewPrevious = "cid_previous"
    static let ScaleBar = "cid_scalebar"
    static let Transcript = "cid_transcript"
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
        
        // snapshot data
        static let Snapshot = "snapshotData"
        enum SnapshotData {
            static let BackandForth = "BackandForth"
            static let Concrete = "Concrete"
            static let PersonalPronouns = "PersonalPronouns"
            static let Transcript = "Transcript"
            static let SentimentAll = "sentimentAll"
            static let SentimentRaw = "sentimentRaw"
            static let TopLevelMetrics = "topLevelMetrics"
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
    
    // Training
    
    enum Training {
        static let TrainingDatabase = "trainingData"
    }
}

// MARK: - Notifications

enum FirebaseNotification {
    static let CharmUserDidUpdate = Notification.Name("notificationCharmUserDidUpdate")
    static let CharmUserIncomingCall = Notification.Name("notificationCharmUserHasIncomingCall")
    static let TrainingModelLoaded = Notification.Name("flashcardsModelHasLoaded")
    static let TrainingHistoryUpdated = Notification.Name("trainingHistoryHasUpdates")
}

// MARK: - Database Constants

enum SummaryItem: String {
    
    case WordChoice = "Concrete_Eng"
    case ConcretePercentage = "Concrete_Raw"
    case BackAndForth = "Talking_Eng"
    case Talking = "Talking_Raw"
    case Connection = "Pronoun_Ctn"
    case ConnectionFirstPerson = "Pronoun_Raw"
    case ToneOfWords = "Emo_Ctn"
    case PositiveWords = "Emo_Pos_Raw"
    case NegativeWords = "Emo_Neg_Raw"
    
}

enum Pronoun: Int {
    case FirstPerson = 1
    case SecondPerson = 2
    case ThirdPerson = 3
    case Plural = 4
    
    var description: String {
        switch self {
        case .FirstPerson:
            return "First"
        case .SecondPerson:
            return "Second"
        case .ThirdPerson:
            return "Third"
        case .Plural:
            return "Plural"
        }
    }
}

// MARK: - Charts

enum ChartType: String {
    case WordChoice = "Word Choice"
    case BackAndForth = "Back and Forth"
    case Connection = "Connection"
    case Emotions = "Emotions"
}
