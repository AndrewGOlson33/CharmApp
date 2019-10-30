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
    static let standard = "com.charismaanalytics.Charm.sub.threetokens.monthly"
    static let premium = "com.charismaanalytics.Charm.sub.fiveTokens.monthly"
}

// MARK: - Server location constants

enum Server {
    static let baseURL = "https://charmtokens.herokuapp.com"
    static let room = "/room"
    static let archive = "/archive"
    static let startArchive = "/start"
    static let stopArchive = "/stop"
}

// MARK: - UI Related
enum SegueID {
    static let friendList = "sid_friendlist"
    static let chat = "sid_chat"
    static let videoCall = "sid_videocall"
    static let detailChart = "sid_detailchart"
    static let trainingChart = "sid_trainingchart"
    static let snapshotsList = "sid_allsnapshots"
    static let metricsTab = "sid_metrics"
    static let videoTraining = "sid_videotraining"
    static let trainingTab = "sid_training"
    static let showInfo = "sid_infopopup"
    static let submitFeedback = "sid_feedback"
    static let subscriptions = "sid_showsubscriptions"
    static let newUser = "sid_newaccount"
    static let subscriptionTable = "sid_subscriptiontable"
}

enum StoryboardID {
    static let navigationHome = "vc_navhome"
    static let videoCall = "vc_videocall"
    static let labelPopover = "vc_labelpopover"
    static let login = "vc_signon"
    static let info = "vc_infodetail"
}

enum CellID {
    static let friendList = "cid_friendlist"
    static let chatList = "cid_chatlist"
    static let emptyChatList = "cid_emptychatlist"
    static let videoList = "cid_video"
    static let summaryMetric = "cid_summary"
    static let viewPrevious = "cid_previous"
    static let scaleBar = "cid_scalebar"
    static let transcript = "cid_transcript"
    static let aiFeedbback = "cid_aifeedback"
    static let snapshotList = "cid_allsnapshots"
    static let subscriptionsList = "cid_subscription"
    static let logOut = "cid_logout"
    static let feedback = "cid_feedback"
    static let termsOfUse = "cid_tou"
    static let privacyPolicy = "cid_privacy"
    static let free = "cid_free"
    static let standard = "cid_standard"
    static let premium = "cid_premium"
}

enum Image {
    static let mic = "icn_mic"
    static let speaker = "icn_speaker"
    static let mute = "icn_mute"
    static let stop = "icn_stop"
    static let chart = "icn_chart"
    static let update = "icn_update"
    static let reset = "icn_reset"
    static let info = "icn_info"
    static let placeholder = "img_placeholder"
}

// MARK: - Firebase Related

enum FirebaseStructure {
    static let usersLocation = "users"
    
    enum CharmUser {
        static let id = "id"
        
        // profile
        static let profileLocation = "userProfile" // base
        
        enum UserProfile {
            static let email = "email"
            static let firstName = "firstName"
            static let lastName = "lastName"
            static let phone = "phone"
            static let membershipStatus = "membershipStatus"
            static let numCredits = "numCredits"
            static let renewDate = "renewDate"
        }
        
        // friends
        static let friendListLocation = "friendList" // base
        enum FriendList {
            static let currentFriends = "currentFriends"
            static let pendingSentApproval = "pendingSentApproval"
            static let pendingReceivedApproval = "pendingReceivedApproval"
            static let sentText = "sentText"
        }
        
        // calls
        static let currentCallLocation = "currentCall"
        enum CurrentCall {
            static let sessionID = "sessionID"
            static let callStatus = "status"
            static let from = "fromUserID"
            static let room = "room"
        }
        
        // snapshot data
        static let snapshotLocation = "snapshotData"
        enum SnapshotData {
            static let backandForth = "BackandForth"
            static let concrete = "Concrete"
            static let personalPronouns = "PersonalPronouns"
            static let transcript = "Transcript"
            static let sentimentAll = "sentimentAll"
            static let sentimentRaw = "sentimentRaw"
            static let topLevelMetrics = "topLevelMetrics"
        }
        
        // token id
        static let token = "tokenID"
        
    }
    
    enum Friend {
        static let id = "id"
        static let firstName = "firstName"
        static let lastName = "lastName"
        static let email = "email"
        static let phone = "phone"
    }
    
    // Archives
    enum Archive {
        static let pending = "pendingArchive"
        static let completed = "completedArchive"
        
        enum ArchiveData {
            static let sessionId = "sessionId"
            static let initiatingUserId = "initiatingUserId"
            static let receivingUserId = "receivingUserId"
        }
    }
    
    // Learning Videos
    enum Videos {
        static let learning = "learning"
        static let sections = "sections"
        
        enum Sections {
            static let fundamentals = "Fundamentals"
            static let supplemental = "Supplemental"
        }
        
        enum VideoItem {
            static let title = "title"
            static let url = "url"
        }
    }
    
    // Training
    
    enum Training {
        static let trainingDatabase = "trainingData"
        static let concreteHistory = "concreteAverage"
        static let emotionHistory = "emotionsAverage"
        static let unclassifiedNouns = "unclassifiedNouns"
        
        enum Stats {
            static let correctRecord = "correctRecord"
            static let numCorrect = "numCorrect"
            static let numQuestions = "numQuestions"
        }
    }
    
    enum DeepLinks {
        static let prefixURL = "https://charismaanalytics.page.link"
        static let bundleID = "com.charismaanalytics.Charm"
        static let minAppVersion = "1.0"
        static let appStoreID = "1458415097"
    }
    
    // Bug Reports
    static let bugs = "bugReports"
    
    enum BugReport {
        static let report = "report"
        static let submitDate = "submitDate"
        static let email = "email"
        static let dateString = "dateString"
    }
    
}

// MARK: - Notifications

enum FirebaseNotification {
    static let CharmUserDidUpdate = Notification.Name("notificationCharmUserDidUpdate")
    static let CharmUserHasCall = Notification.Name("notificationCharmUserHasCall")
    static let trainingModelLoaded = Notification.Name("notificationFlashcardsModelHasLoaded")
    static let trainingHistoryUpdated = Notification.Name("notificationTrainingHistoryHasUpdates")
    static let GotFriendFromLink = Notification.Name("notificationGotFriendFromLink")
    static let SnapshotLoaded = Notification.Name("notificationSnapshotDataLoaded")
    static let NewSnapshot = Notification.Name("notificationnewSnapshotNotificationReceived")
    static let connectionStatusChanged = Notification.Name("notificationConnectionStatusChanged")
    static let showContactListFromNotification = Notification.Name("notificationShowContactListFromNotification")
}

// MARK: - Database Constants

enum SummaryItem: String {
    
    case concrete = "concreteRaw"
    case talkingPercentage = "talkingPercentage"
    case firstPerson = "firstPerson"
    case positiveWords = "emotionsPositive"
    case negativeWords = "emotionsNegative"
    case smilingPercentage = "smilingPercentage"
    case ideaEngagement = "ideaEngagement"
    case conversationEngagement = "conversationEngagement"
    case personalConnection = "personalConnection"
    case emotionalConnection = "emotionalConnection"
}

enum Pronoun: Int {
    case firstPerson = 1
    case plural = 2
    case secondPerson = 3
    case thirdPerson = 4
    
    var description: String {
        switch self {
        case .firstPerson:
            return "First"
        case .secondPerson:
            return "Second"
        case .thirdPerson:
            return "Third"
        case .plural:
            return "Plural"
        }
    }
}

// MARK: - Charts

enum ChartType: String {
    case ideaEngagement = "Idea Engagement"
    case conversation = "Conversation"
    case connection = "Connection"
    case emotions = "Emotions"
}

// MARK: - User Defaults

enum Defaults {
    static let validLicense = "_validLicense"
    static let notFirstLaunch = "_notFirstLaunch"
    static let hasMigrated = "_hasMigrated"
}
