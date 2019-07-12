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

class BugReports {
    
    var reports: Reports = Reports()
    static var shared = BugReports()
    
    init() {
        Database.database().reference().child(FirebaseStructure.Bugs).observe(.value) { (snapshot) in
            guard let value = snapshot.value else { return }
            
            do {
                self.reports = try FirebaseDecoder().decode(Reports.self, from: value)
            } catch let error {
                print("~>There was an error decoding data: \(error)")
            }
        }
    }
    
    func addReport(withText text: String, fromUser email: String) {
        
        DispatchQueue.global(qos: .utility).async {
            do {
                let report = BugReport(report: text, email: email)
                if self.reports.reports == nil {
                    self.reports.reports = [report]
                } else {
                    self.reports.reports?.append(report)
                }
                let data = try FirebaseEncoder().encode(self.reports.reports)
                print("~>trying to set data: \(data)")
                Database.database().reference().child(FirebaseStructure.Bugs).setValue(data)
            } catch let error {
                print("~>There was en error encoding data: \(error)")
            }
        }
    }
    
}

struct Reports: Codable {
    var reports: [BugReport]?
    
    init() {
        reports = []
    }
}

struct BugReport: Codable {
    var report: String
    var submitDate: Date
    var email: String
    
    init(report: String, email: String) {
        self.report = report
        self.submitDate = Date()
        self.email = email
    }
}
