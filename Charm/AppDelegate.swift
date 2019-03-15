//
//  AppDelegate.swift
//  Charm
//
//  Created by Daniel Pratt on 3/6/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit
import Firebase
import FirebaseUI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var user: CharmUser! = nil

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        print("~>Application will terminate.")
        if let videoVC = (window?.rootViewController as? UINavigationController)?.topViewController as? VideoCallViewController {
            print("~>On video vc.")
            videoVC.endCallButtonTapped(videoVC)
        } else {
            print("~>Calling Remove active calls.")
            removeActiveCalls()
        }
    }
    
    func removeActiveCalls() {
        guard let user = self.user else { return }
        let myCallsRef = Database.database().reference().child(FirebaseStructure.Users).child(user.id!).child(FirebaseStructure.CharmUser.Call)
        myCallsRef.removeValue()
        print("~>Did remove active calls.")
    }

}
