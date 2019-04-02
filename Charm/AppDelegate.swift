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
    var friendID: String = ""

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()
        DynamicLinks.performDiagnostics(completion: nil)
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
    
    // MARK: - Deep Link Handling
    
    private func handleAddFriend(withID id: String) {
        print("~>Got a new friend with id: \(id)")
        friendID = id
        NotificationCenter.default.post(name: FirebaseNotification.GotFriendFromLink, object: id)
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        print("~>Continue user activity.")
        let handled = DynamicLinks.dynamicLinks().handleUniversalLink(userActivity.webpageURL!) { [weak self] (dynamiclink, error) in
            if let error = error {
                print(error)
            }
            
            guard let strongSelf = self else { return }
            
            guard let link = dynamiclink?.url else {
                return
            }
            
            let components = URLComponents(url: link, resolvingAgainstBaseURL: false)

            guard let friendID = components?.queryItems?.first(where: { $0.name == "id" })?.value else {
                print("unable to get team id from url")
                return
            }
            
            strongSelf.handleAddFriend(withID: friendID)
        }
        
        return handled
    }
    
    @available(iOS 9.0, *)
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        print("~>open url.")
        return application(app, open: url,
                           sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
                           annotation: "")
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        print("~>Open.")
        if let dynamicLink = DynamicLinks.dynamicLinks().dynamicLink(fromCustomSchemeURL: url) {
            // Handle the deep link. For example, show the deep-linked content or
            // apply a promotional offer to the user's account.
            // ...
            print("~>Got dynamic link: \(dynamicLink)")
            return true
        }
        return false
    }

}
