//
//  CharmBugReports.swift
//  Charm
//
//  Created by Daniel Pratt on 4/12/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import Foundation
import Firebase
import CodableFirebase

struct BugReports {
    
    static var shared = BugReports()
    
    func addReport(withText text: String, fromUser email: String) {
        
        DispatchQueue.global(qos: .utility).async {
            do {
                let report = BugReport(report: text, email: email)
                let data = try FirebaseEncoder().encode(report)
                print("~>trying to set data: \(data)")
                Database.database().reference().child(FirebaseStructure.Bugs).childByAutoId().setValue(data)
            } catch let error {
                print("~>There was en error encoding data: \(error)")
            }
        }
    }
    
}

struct BugReport: Codable {
    var report: String
    var submitDate: Date
    var email: String
    var dateString: String
    
    init(report: String, email: String) {
        self.report = report
        self.submitDate = Date()
        self.email = email
        dateString = self.submitDate.description
    }
}
