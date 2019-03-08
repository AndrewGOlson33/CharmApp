//
//  VideoCallViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 3/7/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit
import OpenTok
import Firebase
import CodableFirebase

class VideoCallViewController: UIViewController {
    
    // MARK: - Properties
    
    // User to establish connection with
    var friend: Friend! = nil
    var myUser: CharmUser! = nil
    
    // Bool to check if there is a disconnection happening right now
    var disconnecting: Bool = false
    
    // Session Variables
    lazy var session: OTSession = {
        return OTSession(apiKey: kApiKey, sessionId: kSessionId, delegate: self)!
    }()
    
    lazy var publisher: OTPublisher = {
        let settings = OTPublisherSettings()
        settings.name = UIDevice.current.name
        return OTPublisher(delegate: self, settings: settings)!
    }()
    
    var subscriber: OTSubscriber?
    
    // OpenTok API key
    var kApiKey = ""
    // Generated session ID will be loaded here
    var kSessionId = ""
    // Generated token will be loaded here
    var kToken = ""
    
    var archiveId: String = ""
    
    // Picture in Picture width / height
    var kMainScreenWidth: CGFloat {
        return view.safeAreaLayoutGuide.layoutFrame.width
    }
    
    var kMainScreenHeight: CGFloat {
        return view.safeAreaLayoutGuide.layoutFrame.height
    }
    
    var kMyScreenWidth: CGFloat {
        return kMainScreenWidth * 0.25
    }
    
    var kMyScreenHeight: CGFloat {
        return kMainScreenHeight * 0.25
    }
    
    // MARK: - View Lifecycle Functions

    override func viewDidLoad() {
        super.viewDidLoad()
      
        doTokenSetup()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if !disconnecting && (session.sessionConnectionStatus == .connected || session.sessionConnectionStatus == .connecting || session.sessionConnectionStatus == .disconnecting) {
            endCallButtonTapped(self)
        }
    }
    
    // MARK: - Private Helper Functions
    
    /**
     * Gets the token to begin the connection process
     * If a session ID is present, use that to start the call with
     */
    fileprivate func doTokenSetup() {
        if !kSessionId.isEmpty {
            getTokensForExistingSession()
        } else {
            getTokensForNewSession()
        }
    }
    
    /**
     * Gets the token to begin the connection process
     * If a session ID is present, use that to start the call with
     */
    fileprivate func getTokensForNewSession() {
        guard let myID = myUser.id, let friendID = friend.id else {
            // TODO: - Error handling (low priority; this should never fail)
            return
        }
        
        let room = "\(myID)+\(friendID)"
        guard let url = URL(string: "https://charmcharismaanalytics.herokuapp.com/room/\(room)") else {
            // TODO: - Error handling (low priority; this should never fail)
            return
        }
        
        configureSession(withURL: url, inviteFriend: true)
    }
    
    /**
     * Gets the token to begin the connection process
     * If a session ID is present, use that to start the call with
     */
    fileprivate func getTokensForExistingSession() {
        guard let myID = myUser.id, let friendID = friend.id else {
            // TODO: - Error handling (low priority; this should never fail)
            return
        }
        let room = "\(friendID)+\(myID)"
        guard let url = URL(string: "https://charmcharismaanalytics.herokuapp.com/room/\(room)") else {
            // TODO: - Error handling (low priority; this should never fail)
            return
        }
        configureSession(withURL: url)
    }
    
    /**
     * Uses URL to generate tokens
     * After tokens are setup, calls do connect to connect to the session
     */
    fileprivate func configureSession(withURL url: URL, inviteFriend: Bool = false) {
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration)
        let dataTask = session.dataTask(with: url) {
            (data: Data?, response: URLResponse?, error: Error?) in
            
            guard error == nil, let data = data else {
                print(error!)
                return
            }
            
            do {
                let dict = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [AnyHashable: Any]
                self.kApiKey = dict?["apiKey"] as? String ?? ""
                self.kSessionId = dict?["sessionId"] as? String ?? ""
                self.kToken = dict?["token"] as? String ?? ""
                print("~>Got a sessionID: \(self.kSessionId)")
                print("~>Got a token: \(self.kToken)")
                
                let status = inviteFriend ? Call.CallStatus.outgoing : Call.CallStatus.connected
                self.updateCallStatus(withSessionID: self.kSessionId, status: status)
                self.doConnect()
            } catch let error {
                print("~>There was an error decoding json object: \(error)")
                return
            }
            
        }
        dataTask.resume()
        session.finishTasksAndInvalidate()
    }
    
    // TODO: - Handle case where other user is already on a call
    /**
     * Updates the user's call status
     * Also update the friend's call status if they were invited
    */
    fileprivate func updateCallStatus(withSessionID id: String, status: Call.CallStatus) {
        // Setup Call Objects
        var myCall: Call!
        var friendCall: Call!
        
        if status == .outgoing {
            myCall = Call(sessionID: id, status: .outgoing, from: friend.id!)
            friendCall = Call(sessionID: id, status: .incoming, from: myUser.id!)
        } else {
            myCall = Call(sessionID: id, status: .connected, from: friend.id!)
            friendCall = Call(sessionID: id, status: .connected, from: myUser.id!)
        }
        
        // Write call objects to Firebase
        do {
            // encode data
            let myCallData = try FirebaseEncoder().encode(myCall)
            let friendCallData = try FirebaseEncoder().encode(friendCall)
            
            // upload to firebase
            let usersRef = Database.database().reference().child(FirebaseStructure.Users)
            usersRef.child(friend.id!).child(FirebaseStructure.CharmUser.Call).setValue(friendCallData)
            usersRef.child(myUser.id!).child(FirebaseStructure.CharmUser.Call).setValue(myCallData)
        } catch let error {
            print("~>Got an error converting objects for firebase: \(error)")
        }
    }
    
    /**
     * Asynchronously begins the session connect process. Some time later, we will
     * expect a delegate method to call us back with the results of this action.
     */
    fileprivate func doConnect() {
        var error: OTError?
        defer {
            processError(error)
        }
        
        session.connect(withToken: kToken, error: &error)
    }
    
    /**
     * Sets up an instance of OTPublisher to use with this session. OTPubilsher
     * binds to the device camera and microphone, and will provide A/V streams
     * to the OpenTok session.
     */
    fileprivate func doPublish() {
        var error: OTError?
        defer {
            processError(error)
        }
        
        session.publish(publisher, error: &error)
        
        if let pubView = publisher.view {
            pubView.frame = CGRect(x: 20, y: 20, width: kMyScreenWidth, height: kMyScreenHeight)
            pubView.contentMode = .scaleToFill
            view.addSubview(pubView)
        }
        
        // start archiving
        startArchive()
    }
    
    /**
     * Instantiates a subscriber for the given stream and asynchronously begins the
     * process to begin receiving A/V content for this stream. Unlike doPublish,
     * this method does not add the subscriber to the view hierarchy. Instead, we
     * add the subscriber only after it has connected and begins receiving data.
     */
    fileprivate func doSubscribe(_ stream: OTStream) {
        var error: OTError?
        defer {
            processError(error)
        }
        subscriber = OTSubscriber(stream: stream, delegate: self)
        
        session.subscribe(subscriber!, error: &error)
    }
    
    fileprivate func cleanupSubscriber() {
        subscriber?.view?.removeFromSuperview()
        subscriber = nil
    }
    
    fileprivate func cleanupPublisher() {
        publisher.view?.removeFromSuperview()
    }
    
    fileprivate func processError(_ error: OTError?) {
        if let err = error {
            DispatchQueue.main.async {
                let controller = UIAlertController(title: "Error", message: err.localizedDescription, preferredStyle: .alert)
                controller.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(controller, animated: true, completion: nil)
            }
        }
    }
    
    func startArchive() {
        let fullURL = "https://charmcharismaanalytics.herokuapp.com/archive/start"
        let url = URL(string: fullURL)
        var urlRequest: URLRequest? = nil
        if let url = url {
            urlRequest = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10)
        }
        
        guard var request = urlRequest else { return }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        let dict = [
            "sessionId": kSessionId
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
        
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration)
        
        let dataTask = session.dataTask(with: request) { (data, response, error) in
        
            print("~>Got response: \(String(describing: response))")
            if let error = error {
                print("~>Got an error trying to start an archive: \(error)")
            } else {
                print("~>Archive started.")
            }
        }
        
        dataTask.resume()
        session.finishTasksAndInvalidate()
    }

    
    func stopArchive() {
        let fullURL = "https://charmcharismaanalytics.herokuapp.com/archive/\(archiveId)/stop"
        let url = URL(string: fullURL)
        var urlRequest: URLRequest? = nil
        if let url = url {
            urlRequest = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10)
        }
        
        guard var request = urlRequest else { return }
        request.httpMethod = "POST"
        
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration)
        
        let dataTask = session.dataTask(with: request) { (data, response, error) in
            print("~>Got response: \(String(describing: response))")
            if let error = error {
                print("~>Got an error trying to stop an archive: \(error)")
            } else {
                print("~>Archive stopped.")
            }
        }
        
        dataTask.resume()
        session.finishTasksAndInvalidate()
    }


    // MARK: - Button Handling
    
    // Disconnects from the session
    @IBAction func endCallButtonTapped(_ sender: Any) {
        disconnecting = true
        var error: OTError?
        defer {
            processError(error)
            if error == nil, let _ = sender as? UIButton { navigationController?.popViewController(animated: true) }
        }
        
        session.disconnect(&error)
        stopArchive()
    }
    
}

// MARK: - OTSession delegate callbacks
extension VideoCallViewController: OTSessionDelegate {
    func sessionDidConnect(_ session: OTSession) {
        print("~>Session connected")
        doPublish()
    }
    
    func sessionDidDisconnect(_ session: OTSession) {
        print("~>Session disconnected")
        disconnecting = false
        DispatchQueue.main.async {
            // remove call
            let call: Call? = nil
            do {
                let callData = try FirebaseEncoder().encode(call)
                Database.database().reference().child(FirebaseStructure.Users).child(self.myUser.id!).child(FirebaseStructure.CharmUser.Call).setValue(callData)
            } catch let error {
                print("~>There was an error converting the nil call object: \(error)")
            }
        }
    }
    
    func session(_ session: OTSession, streamCreated stream: OTStream) {
        print("~>Session streamCreated: \(stream.streamId)")
        if subscriber == nil {
            doSubscribe(stream)
        }
    }
    
    func session(_ session: OTSession, streamDestroyed stream: OTStream) {
        print("~>Session streamDestroyed: \(stream.streamId)")
        if let subStream = subscriber?.stream, subStream.streamId == stream.streamId {
            cleanupSubscriber()
        }
    }
    
    func session(_ session: OTSession, didFailWithError error: OTError) {
        print("~>session Failed to connect: \(error.localizedDescription)")
    }
    
    func session(_ session: OTSession, archiveStartedWithId archiveId: String, name: String?) {
        print("~>archive began using archiveID: \(archiveId)")
        self.archiveId = archiveId
    }
    
    func session(_ session: OTSession, archiveStoppedWithId archiveId: String) {
        // TODO: - Add Archive ID to firebase
        print("~>archive with archiveID: \(archiveId) ended.")
    }
    
}

// MARK: - OTPublisher delegate callbacks
extension VideoCallViewController: OTPublisherDelegate {
    func publisher(_ publisher: OTPublisherKit, streamCreated stream: OTStream) {
        print("~>Publishing")
    }
    
    func publisher(_ publisher: OTPublisherKit, streamDestroyed stream: OTStream) {
        cleanupPublisher()
        if let subStream = subscriber?.stream, subStream.streamId == stream.streamId {
            cleanupSubscriber()
        }
    }
    
    func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
        print("~>Publisher failed: \(error.localizedDescription)")
    }
}

// MARK: - OTSubscriber delegate callbacks
extension VideoCallViewController: OTSubscriberDelegate {
    func subscriberDidConnect(toStream subscriberKit: OTSubscriberKit) {
        print("~>Subscriber did connect, setting up view.")
        if let subsView = subscriber?.view {
            subsView.frame = CGRect(x: 0, y: 0, width: kMainScreenWidth, height: kMainScreenHeight)
            view.addSubview(subsView)
            view.sendSubviewToBack(subsView)
        }
    }
    
    func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {
        print("~>Subscriber failed: \(error.localizedDescription)")
    }
}
