//
//  Constants.swift
//  Charm
//
//  Created by Daniel Pratt on 3/6/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import Foundation

// MARK: - Subscription Product ID's

enum SubscriptionID {
    static let Standard = "com.charismaanalytics.Charm.sub.threetokens.monthly"
    static let Premium = "com.charismaanalytics.Charm.sub.fiveTokens.monthly"
}

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
    static let Chat = "sid_chat"
    static let VideoCall = "sid_videocall"
    static let DetailChart = "sid_detailchart"
    static let TrainingChart = "sid_trainingchart"
    static let SnapshotsList = "sid_allsnapshots"
    static let MetricsTab = "sid_metrics"
    static let VideoTraining = "sid_videotraining"
    static let TrainingTab = "sid_training"
    static let ShowInfo = "sid_infopopup"
    static let SubmitFeedback = "sid_feedback"
    static let Subscriptions = "sid_showsubscriptions"
    static let NewUser = "sid_newaccount"
    static let SubscriptionTable = "sid_subscriptiontable"
}

enum StoryboardID {
    static let NavigationHome = "vc_navhome"
    static let VideoCall = "vc_videocall"
    static let LabelPopover = "vc_labelpopover"
    static let Login = "vc_signon"
    static let Info = "vc_infodetail"
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
    static let AIFeedbback = "cid_aifeedback"
    static let SnapshotList = "cid_allsnapshots"
    static let SubscriptionsList = "cid_subscription"
    static let LogOut = "cid_logout"
    static let Feedback = "cid_feedback"
    static let TermsOfUse = "cid_tou"
    static let PrivacyPolicy = "cid_privacy"
    static let Free = "cid_free"
    static let Standard = "cid_standard"
    static let Premium = "cid_premium"
}

enum Image {
    static let Mic = "icn_mic"
    static let Speaker = "icn_speaker"
    static let Mute = "icn_mute"
    static let Stop = "icn_stop"
    static let Chart = "icn_chart"
    static let Update = "icn_update"
    static let Reset = "icn_reset"
    static let Info = "icn_info"
    static let Placeholder = "img_placeholder"
}

// MARK: - Firebase Related

enum FirebaseStructure {
    static let Users = "users"
    
    enum CharmUser {
        static let ID = "id"
        
        // profile
        static let Profile = "userProfile" // base
        
        enum UserProfile {
            static let Email = "email"
            static let FirstName = "firstName"
            static let LastName = "lastName"
            static let Phone = "phone"
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
            static let SentText = "sentText"
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
        
        // token id
        static let Token = "tokenID"
        
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
        static let ConcreteHistory = "concreteAverage"
        static let EmotionHistory = "emotionsAverage"
        static let SandboxHistory = "sandboxHistory"
        static let UnclassifiedNouns = "unclassifiedNouns"
    }
    
    enum DeepLinks {
        static let PrefixURL = "https://charismaanalytics.page.link"
        static let BundleID = "com.charismaanalytics.Charm"
        static let MinAppVersion = "1.0"
        static let AppStoreID = "1458415097"
    }
    
    // Bug Reports
    static let Bugs = "bugReports"
}

// MARK: - Notifications

enum FirebaseNotification {
    static let CharmUserDidUpdate = Notification.Name("notificationCharmUserDidUpdate")
    static let CharmUserIncomingCall = Notification.Name("notificationCharmUserHasIncomingCall")
    static let TrainingModelLoaded = Notification.Name("flashcardsModelHasLoaded")
    static let TrainingHistoryUpdated = Notification.Name("trainingHistoryHasUpdates")
    static let GotFriendFromLink = Notification.Name("gotFriendFromLink")
    static let SnapshotLoaded = Notification.Name("snapshotDataLoaded")
    static let NewSnapshot = Notification.Name("newSnapshotNotificationReceived")
}

// MARK: - Database Constants

enum SummaryItem: String {
    
    case Concrete = "concreteRaw"
    case TalkingPercentage = "talkingPercentage"
    case FirstPerson = "firstPerson"
    case PositiveWords = "emotionsPositive"
    case NegativeWords = "emotionsNegative"
    case SmilingPercentage = "smilingPercentage"
    case IdeaEngagement = "ideaEngagement"
    case ConversationEngagement = "conversationEngagement"
    case PersonalConnection = "personalConnection"
    case EmotionalConnection = "emotionalConnection"
//    case ConcretePercentage = "Concrete_Raw"
//    case BackAndForth = "Talking_Eng"
//    case Talking = "Talking_Raw"
//    case Connection = "Pronoun_Ctn"
//    case ConnectionFirstPerson = "Pronoun_Raw"
//    case ToneOfWords = "Emo_Ctn"
//    case PositiveWords = "Emo_Pos_Raw"
//    case NegativeWords = "Emo_Neg_Raw"
    
}

enum Pronoun: Int {
    case FirstPerson = 1
    case Plural = 2
    case SecondPerson = 3
    case ThirdPerson = 4
    
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
    case IdeaEngagement = "Idea Engagement"
    case Conversation = "Conversation"
    case Connection = "Connection"
    case Emotions = "Emotions"
}

// MARK: - User Defaults

enum Defaults {
    static let validLicense = "_validLicense"
    static let notFirstLaunch = "_notFirstLaunch"
}
