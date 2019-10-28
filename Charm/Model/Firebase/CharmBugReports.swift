//
//  CharmBugReports.swift
//  Charm
//
//  Created by Daniel Pratt on 4/12/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import Foundation
import Firebase

struct BugReports {
    
    static var shared = BugReports()
    
    func addReport(withText text: String, fromUser email: String) {
        
        DispatchQueue.global(qos: .utility).async {
            let _ = BugReport(report: text, email: email)
        }
    }
    
}

struct BugReport: FirebaseItem {
    
    var id: String?
    var ref: DatabaseReference?
    var report: String
    var submitDate: Double
    var email: String
    var dateString: String
    
    init(report: String, email: String) {
        self.report = report
        self.submitDate = Date().timeIntervalSinceReferenceDate
        self.email = email
        dateString = self.submitDate.description
        
        ref = Database.database().reference().child(FirebaseStructure.bugs).childByAutoId()
        id = ref?.key
        
        self.save()
    }
    
    init(snapshot: DataSnapshot) throws {
        guard let values = snapshot.value as? [String:Any] else { throw FirebaseItemError.invalidData }
        id = snapshot.key
        ref = snapshot.ref
        report = values[FirebaseStructure.BugReport.report] as? String ?? ""
        submitDate = values[FirebaseStructure.BugReport.submitDate] as? Double ?? 0.0
        email = values[FirebaseStructure.BugReport.email] as? String ?? ""
        let date = Date(timeIntervalSinceReferenceDate: submitDate)
        dateString = date.description
    }
    
    func toAny() -> [AnyHashable : Any] {
        return [
            FirebaseStructure.BugReport.report : report as NSString,
            FirebaseStructure.BugReport.submitDate : submitDate as NSNumber,
            FirebaseStructure.BugReport.email : email as NSString,
            FirebaseStructure.BugReport.dateString : dateString as NSString
        ]
    }
}
