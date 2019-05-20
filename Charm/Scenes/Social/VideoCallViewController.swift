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
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var viewConnecting: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var btnEndCall: UIButton!
    @IBOutlet weak var lblCallTimer: UILabel!
    
    // MARK: - Properties
    
    // User to establish connection with
    var friend: Friend! = nil
    var myUser: CharmUser! = nil
    
    // Used to set screen brightness back to normal level after call ends
    var brightness: CGFloat = 0
    let originalBrightness: CGFloat = UIScreen.main.brightness
    
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
    var callWasConnected: Bool = false
    
    // Token Consumption Timer
    var useTokenTimer: Timer = Timer()
    var endArchiveTimer: Timer = Timer()
    
    // bool for if archive is already stopped
    var archiveHasBeenStopped: Bool = false
    
    // call timer
    var shouldShowCallTimer: Bool = false
    var callTime: Int = 0
    var callTimer: Timer = Timer()
    
    // OpenTok API key
    var kApiKey = ""
    // Generated session ID will be loaded here
    var kSessionId = ""
    // Generated token will be loaded here
    var kToken = ""
    
    var archiveId: String = ""
    var pendingArchive: SessionArchive? = nil
    
    // Picture in Picture width / height
    var kMainScreenWidth: CGFloat {
        return view.safeAreaLayoutGuide.layoutFrame.width
    }
    
    var kMainScreenHeight: CGFloat {
        return view.frame.height
    }
    
    var kMyScreenWidth: CGFloat {
        return kMainScreenWidth * 0.25
    }
    
    var kMyScreenHeight: CGFloat {
        return kMainScreenHeight * 0.25
    }
    
    // variable set to true if user is the one initiating call
    var isInitiatingUser: Bool = false
    
    var tap: UITapGestureRecognizer! = nil
    
    // MARK: - View Lifecycle Functions

    override func viewDidLoad() {
        super.viewDidLoad()
      
        doTokenSetup()
        
        // round corners of connecting view
        viewConnecting.layer.cornerRadius = 20
        viewConnecting.layer.shadowColor = UIColor.white.cgColor
        viewConnecting.layer.shadowRadius = 8
        viewConnecting.layer.shadowOpacity = 0.6
        viewConnecting.layer.shadowOffset = CGSize(width: 2, height: 2)
        
        // Fade cancel button
        hideButton()
        
        // timer alpha should be 0 at the start
        lblCallTimer.alpha = 0.0
        
        // setup tap gesture
        tap = UITapGestureRecognizer(target: self, action: #selector(handleScreenTap(_:)))
        tap.numberOfTapsRequired = 1
        tap.numberOfTouchesRequired = 1
        tap.delegate = self
        view.addGestureRecognizer(tap)
        
        brightness = UIScreen.main.brightness
        if brightness != 1.0 { increaseScreenBrightness() }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.isHidden = false
        
        // Set Brightness back to the original value
        UIScreen.main.brightness = originalBrightness
        
        if useTokenTimer.isValid { useTokenTimer.invalidate() }
        if endArchiveTimer.isValid { endArchiveTimer.invalidate() }
        if callTimer.isValid { callTimer.invalidate() }
        
        if !disconnecting && (session.sessionConnectionStatus == .connected || session.sessionConnectionStatus == .connecting || session.sessionConnectionStatus == .disconnecting) {
            endCall(self)
        }
    }
    
    // MARK: - Private Helper Functions
    
    private func increaseScreenBrightness() {
        guard brightness != 1.0 else { return }
        
        brightness += 0.1
        if brightness > 1.0 { brightness = 1.0 }
        
        UIScreen.main.brightness = brightness
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.increaseScreenBrightness()
        }
    }
    
    @objc private func handleScreenTap(_ notification: UITapGestureRecognizer) {
        if shouldShowCallTimer {
            lblCallTimer.isHidden = false
        }
        
        if self.btnEndCall.alpha == 0 {
            UIView.animate(withDuration: 0.25, delay: 0.0, options: [.curveEaseIn, .allowUserInteraction], animations: {
                self.btnEndCall.alpha = 1.0
                self.lblCallTimer.alpha = 1.0
            }) { (_) in
                self.hideButton()
            }
        }
    }
    
    private func hideButton() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            UIView.animate(withDuration: 0.8, delay: 0.0, options: [.curveEaseIn, .allowUserInteraction], animations: {
                self.btnEndCall.alpha = 0.0
                self.lblCallTimer.alpha = 0.0
            })
        }
    }
    
    fileprivate func showCallErrorAlert() {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Unable to Place Call", message: "An error occurred preventing the call from being placed.  Please try again later", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                self.navigationController?.popViewController(animated: true)
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    /**
     * Gets the token to begin the connection process
     * If a session ID is present, use that to start the call with
     */
    fileprivate func doTokenSetup() {
        viewConnecting.isHidden = false
        activityIndicator.startAnimating()
        if !kSessionId.isEmpty {
            getTokensForExistingSession()
        } else {
            isInitiatingUser = true
            getTokensForNewSession()
        }
    }
    
    /**
     * Gets the token to begin the connection process
     * If a session ID is present, use that to start the call with
     */
    fileprivate func getTokensForNewSession() {
        guard let myID = myUser.id, let friendID = friend.id else {
            self.showCallErrorAlert()
            return
        }
        
        let room = "\(myID)+\(friendID)"
        guard let url = URL(string: "\(Server.BaseURL)\(Server.Room)/\(room)") else {
            self.showCallErrorAlert()
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
            self.showCallErrorAlert()
            return
        }
        let room = "\(friendID)+\(myID)"
        guard let url = URL(string: "\(Server.BaseURL)\(Server.Room)/\(room)") else {
            self.showCallErrorAlert()
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
    
    /**
     * Updates the user's call status
     * Also update the friend's call status if they were invited
    */
    fileprivate func updateCallStatus(withSessionID id: String, status: Call.CallStatus) {
        // Setup Call Objects and reference
        var myCall: Call!
        var friendCall: Call!
        let usersRef = Database.database().reference().child(FirebaseStructure.Users)
        
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
            usersRef.child(friend.id!).child(FirebaseStructure.CharmUser.Call).setValue(friendCallData)
            usersRef.child(myUser.id!).child(FirebaseStructure.CharmUser.Call).setValue(myCallData)
        } catch let error {
            print("~>Got an error converting objects for firebase: \(error)")
            showCallErrorAlert()
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
        let fullURL = "\(Server.BaseURL)\(Server.Archive)\(Server.StartArchive)"
        let url = URL(string: fullURL)
        var urlRequest: URLRequest? = nil
        if let url = url {
            urlRequest = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10)
        }
        
        guard var request = urlRequest else { return }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        let dict = [
            "sessionId": kSessionId,
            "userId" : myUser.id!
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
                self.pendingArchive = SessionArchive(id: self.kSessionId, callerId: self.myUser.id!, calledId: self.friend.id!, callerName: self.myUser.userProfile.firstName, calledName: self.friend.firstName)
                guard let pending = self.pendingArchive else { return }
                print("~>Added pending to firebase: \(pending.addPending())")
            }
        }
        
        dataTask.resume()
        session.finishTasksAndInvalidate()
        
        
    }

    
    func stopArchive() {
        
        guard !archiveHasBeenStopped else { return }
        
        let fullURL = "\(Server.BaseURL)\(Server.Archive)/\(archiveId)\(Server.StopArchive)"
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
        print("~>End call button tapped")
        let endAlert = UIAlertController(title: "End Call?", message: "Are you sure you want to end the call?", preferredStyle: .alert)
        endAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (_) in
            self.endCall(self.btnEndCall!)
        }))
        endAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        present(endAlert, animated: true, completion: nil)
    }
    
    private func endCall(_ sender: Any) {
        disconnecting = true
        var error: OTError?
        if useTokenTimer.isValid { useTokenTimer.invalidate() }
        if endArchiveTimer.isValid { endArchiveTimer.invalidate() }
        if callTimer.isValid { callTimer.invalidate() }
        defer {
            processError(error)
            if error == nil, let _ = sender as? UIButton { navigationController?.popViewController(animated: true) }
        }
        
        session.disconnect(&error)
        stopArchive()
        if !callWasConnected {
            print("~>Call was not connected.")
            // remove both user's call data
            let usersRef = Database.database().reference().child(FirebaseStructure.Users)
            usersRef.child(myUser.id!).child(FirebaseStructure.CharmUser.Call).removeValue()
            usersRef.child(friend.id!).child(FirebaseStructure.CharmUser.Call).removeValue()
            print("~>Removed call references.")
            
            // remove the pending archive
            if let pending = pendingArchive {
                print("~>Removed archive from pending list: \(pending.removePending())")
            }
        }
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
        // TODO: - Find out if we need archive ID in firebase
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
        callWasConnected = true
        DispatchQueue.main.async {
            if let subsView = self.subscriber?.view {
                subsView.frame = CGRect(x: 0, y: 0, width: self.kMainScreenWidth, height: self.kMainScreenHeight)
                self.view.addSubview(subsView)
                self.view.sendSubviewToBack(subsView)
                
                UIView.animate(withDuration: 0.5, animations: {
                    self.viewConnecting.alpha = 0.0
                    self.activityIndicator.stopAnimating()
                }) { (_) in
                    self.viewConnecting.alpha = 1.0
                    self.viewConnecting.isHidden = true
                }
            }
        }
        
        useTokenTimer = Timer.scheduledTimer(withTimeInterval: 420.0, repeats: false, block: { (_) in
            
            if self.pendingArchive != nil {
                print("~>Setting archive to complete")
                self.pendingArchive?.setArchiveComplete()
            }
            
            switch self.isInitiatingUser {
            case true:
                print("~>Should be taking away a token.")
                self.myUser.userProfile.numCredits -= 1
                let tokens = self.myUser.userProfile.numCredits < 0 ? 0 : self.myUser.userProfile.numCredits
                Database.database().reference().child(FirebaseStructure.Users).child(self.myUser.id!).child(FirebaseStructure.CharmUser.Profile).child(FirebaseStructure.CharmUser.UserProfile.NumCredits).setValue(tokens)
            case false:
                print("~>Not the initiating user.")
            }
            
            self.useTokenTimer.invalidate()
        })
        
        endArchiveTimer = Timer.scheduledTimer(withTimeInterval: 720.0, repeats: false, block: { (_) in
            self.stopArchive()
            self.archiveHasBeenStopped = true
            self.endArchiveTimer.invalidate()
        })
        
        shouldShowCallTimer = true
        handleScreenTap(UITapGestureRecognizer())
        
        callTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (_) in
            self.callTime += 1
            let minutes = self.callTime / 60
            let seconds = self.callTime % 60
            
            let minString = String(format: "%02d", minutes)
            let secString = String(format: "%02d", seconds)
            
            print("~>Set call time: \(minString):\(secString)")
            
            let timeString = "\(minString):\(secString)"
            self.lblCallTimer.text = timeString
        })

    }
    
    func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {
        print("~>Subscriber failed: \(error.localizedDescription)")
    }
}

extension VideoCallViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !touch.view!.isKind(of: UIButton.self)
    }
    
}
