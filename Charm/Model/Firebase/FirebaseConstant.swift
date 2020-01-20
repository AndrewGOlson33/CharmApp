//
//  FirebaseConstant.swift
//  Charm
//
//  Created by Daniel Pratt on 11/1/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import Foundation
import Firebase

struct FirebaseConstants: FirebaseItem {
    var id: String?
    var ref: DatabaseReference?
    var taglineSmallerTop = "Captivate their Mind & "
    var talineLargerBottom = "Connect to their Heart"
    var introStep01Line01 = "Talk with a Friend"
    var introStep01Line02 = "(Or a Coach)"
    var introStep02Line01 = "Discover How Your Words"
    var introStep02Line02 = "Engage their Heart and Mind"
    var introStep03Line01 = "Receive"
    var introStep03Line02 = "Life Changing Insights"
    var introStep04Line01 = "Master Conversation"
    var introStep04Line02 = "with Guided Training"
    var metricDescWord = "What You are Talking About"
    var metricDescConvo = "The Flow of the Conversation"
    var metricDescPersonal = "Who You are Talking About"
    var metricDescEmotions = "The Emotional Journey of Your Words"
    var metricTrainingWord = "Captivate Their Mind"
    var metricTrainingConvo = "Create Engaging Conversation"
    var metricTrainingPersonal = "Become their Best Friends"
    var metricTrainingEmotions = "Triggering (the Right) Emotions"
    
    init(snapshot: DataSnapshot) throws {
        guard snapshot.exists() else{ throw FirebaseItemError.noSnapshot }
        guard let values = snapshot.value as? [String : String] else { throw FirebaseItemError.invalidData }
        id = snapshot.key
        ref = snapshot.ref
        taglineSmallerTop = values[FirebaseStructure.AppConstants.taglineSmallerTop] ?? taglineSmallerTop
        talineLargerBottom = values[FirebaseStructure.AppConstants.talineLargerBottom] ?? talineLargerBottom
        introStep01Line01 = values[FirebaseStructure.AppConstants.introStep01Line01] ?? introStep01Line01
        introStep01Line02 = values[FirebaseStructure.AppConstants.introStep01Line02] ?? introStep01Line02
        introStep02Line01 = values[FirebaseStructure.AppConstants.introStep02Line01] ?? introStep02Line01
        introStep02Line02 = values[FirebaseStructure.AppConstants.introStep02Line02] ?? introStep02Line02
        introStep03Line01 = values[FirebaseStructure.AppConstants.introStep03Line01] ?? introStep03Line01
        introStep03Line02 = values[FirebaseStructure.AppConstants.introStep03Line02] ?? introStep03Line02
        introStep04Line01 = values[FirebaseStructure.AppConstants.introStep04Line01] ?? introStep04Line01
        introStep04Line02 = values[FirebaseStructure.AppConstants.introStep04Line02] ?? introStep04Line02
        metricDescWord = values[FirebaseStructure.AppConstants.metricDescWord] ?? metricDescWord
        metricDescConvo = values[FirebaseStructure.AppConstants.metricDescConvo] ?? metricDescConvo
        metricDescPersonal = values[FirebaseStructure.AppConstants.metricDescPersonal] ?? metricDescPersonal
        metricDescEmotions = values[FirebaseStructure.AppConstants.metricDescEmotions] ?? metricDescEmotions
        metricTrainingWord = values[FirebaseStructure.AppConstants.metricTrainingWord] ?? metricTrainingWord
        metricTrainingConvo = values[FirebaseStructure.AppConstants.metricTrainingConvo] ?? metricTrainingConvo
        metricTrainingPersonal = values[FirebaseStructure.AppConstants.metricTrainingPersonal] ?? metricTrainingPersonal
        metricTrainingEmotions = values[FirebaseStructure.AppConstants.metricTrainingEmotions] ?? metricTrainingEmotions
    }
    
    func toAny() -> [AnyHashable : Any] {
        return [:]
    }
    
    func save() {
        return
    }
}
