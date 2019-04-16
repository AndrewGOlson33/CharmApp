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
import UserNotificationsUI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var user: CharmUser! = nil
    var friendID: String = ""
    let gcmMessageIDKey = "gcm.message_id"
    var restoreFromBackground = false
    var showContactListFromNotification: Bool = false
    
    // MARK: - App Delegate Functions

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()
        Database.database().isPersistenceEnabled = true
        DynamicLinks.performDiagnostics(completion: nil)
        
        Messaging.messaging().delegate = self
        
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        
        
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        print("~>Will resign active")
        restoreFromBackground = true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("~>Did enter background")
        restoreFromBackground = true
    }
    
    // [START receive_message]
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("~>did receive remote Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        if let aps = userInfo["aps"] as? [AnyHashable:Any], let alert = aps["alert"] as? [AnyHashable:Any], let title = alert["title"] as? String {
            print("~>Got a title: \(title)")
            if title.contains("friend request") { showContactListFromNotification = true }
        } else {
            print("~>Something is invalid.")
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("~>fetch completion Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        if let aps = userInfo["aps"] as? [AnyHashable:Any], let alert = aps["alert"] as? [AnyHashable:Any], let title = alert["title"] as? String {
            print("~>Got a title: \(title)")
            if title.contains("friend request") { showContactListFromNotification = true }
        } else {
            print("~>Something is invalid.")
        }
        
        completionHandler(UIBackgroundFetchResult.newData)
    }
    // [END receive_message]
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Unable to register for remote notifications: \(error.localizedDescription)")
    }
    
    // This function is added here only for debugging purposes, and can be removed if swizzling is enabled.
    // If swizzling is disabled then this function must be implemented so that the APNs token can be paired to
    // the FCM registration token.
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("APNs token retrieved: \(deviceToken)")
        
        // With swizzling disabled you must set the APNs token here.
        // Messaging.messaging().apnsToken = deviceToken
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
    
    // MARK: - Helper Functions
    
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
            
            guard let link = dynamicLink.url else { return false }
            
            let components = URLComponents(url: link, resolvingAgainstBaseURL: false)
            
            guard let friendID = components?.queryItems?.first(where: { $0.name == "id" })?.value else {
                print("unable to get team id from url")
                return false
            }
            
            handleAddFriend(withID: friendID)
            
            return true
        }
        return false
    }

}

// MARK: - Notification Delegates

// [START ios_10_message_handling]
@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {
    
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("~> un notification center Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        if let aps = userInfo["aps"] as? [AnyHashable:Any], let alert = aps["alert"] as? [AnyHashable:Any], let title = alert["title"] as? String {
            print("~>Got a title: \(title)")
//            if title.contains("friend request") { showContactListFromNotification = true }
        } else {
            print("~>Something is invalid.")
        }
        
        // Change this to your preferred presentation option
        completionHandler([])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("~>Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        if let aps = userInfo["aps"] as? [AnyHashable:Any], let alert = aps["alert"] as? [AnyHashable:Any], let title = alert["title"] as? String {
            print("~>Got a title: \(title)")
            if title.contains("friend request") { showContactListFromNotification = true }
        } else {
            print("~>Something is invalid.")
        }
        
        completionHandler()
    }
}
// [END ios_10_message_handling]

extension AppDelegate: MessagingDelegate {
    // [START refresh_token]
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")
        
        let dataDict:[String: String] = ["token": fcmToken]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
    }
    // [END refresh_token]
    // [START ios_10_data_message]
    // Receive data messages on iOS 10+ directly from FCM (bypassing APNs) when the app is in the foreground.
    // To enable direct data messages, you can set Messaging.messaging().shouldEstablishDirectChannel to true.
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print("Received data message: \(remoteMessage.appData)")
    }
    // [END ios_10_data_message]
}
