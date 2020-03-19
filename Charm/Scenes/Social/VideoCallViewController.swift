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
import AVKit

class Publisher {
    var publisher: OTPublisher
    
    static var shared: Publisher = Publisher()
    
    init() {
        let settings = OTPublisherSettings()
        settings.name = UIDevice.current.name
        publisher = OTPublisher(delegate: nil, settings: settings)!
    }
}

class VideoCallViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var viewConnecting: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var btnEndCall: UIButton!
    @IBOutlet weak var callProgressBar: UIProgressView!
    @IBOutlet weak var callProgressLabel: UILabel!
    @IBOutlet weak var recordingLabel: UILabel!
    
    // MARK: - Properties
    
    // User to establish connection with
    var friend: Friend! = nil
    var myUser: CharmUser! = nil
    
    // Bool to check if there is a disconnection happening right now
    var disconnecting: Bool = false
    var userInitiatedDisconnect: Bool = false
    
    // Session Variables
    lazy var session: OTSession! = {
        return OTSession(apiKey: kApiKey, sessionId: kSessionId, delegate: self)
    }()
    
    lazy var publisher = Publisher.shared.publisher
    
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
    var requiredCallTime: Int = 480 // 8 mins
    
    // OpenTok API key
    var kApiKey = ""
    // Generated session ID will be loaded here
    var kSessionId = ""
    // Generated token will be loaded here
    var kToken = ""
    // Room connected to
    var room = ""
    
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
        
        // set publisher delegate
        publisher.delegate = self
        
        // make sure app delegate incoming call is set to false
        DispatchQueue.main.async {
            (UIApplication.shared.delegate as! AppDelegate).incomingCall = false
        }
      
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
        callProgressLabel.alpha = 0.0
        callProgressBar.alpha = 0.0
        recordingLabel.alpha = 0.0
        
        // setup tap gesture
        tap = UITapGestureRecognizer(target: self, action: #selector(handleScreenTap(_:)))
        tap.numberOfTapsRequired = 1
        tap.numberOfTouchesRequired = 1
        tap.delegate = self
        view.addGestureRecognizer(tap)
        
        DispatchQueue.main.async {
            let delegate = UIApplication.shared.delegate as! AppDelegate
            delegate.incomingCall = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord)
        } catch let error {
            print("~>There was an error setting avaudio category: \(error)")
        }
        
        // prevent display from dimming
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.isHidden = false
        
        // return idle timer to normal
        UIApplication.shared.isIdleTimerDisabled = false
        
        if useTokenTimer.isValid { useTokenTimer.invalidate() }
        if endArchiveTimer.isValid { endArchiveTimer.invalidate() }
        if callTimer.isValid { callTimer.invalidate() }
        
        if !disconnecting && (session.sessionConnectionStatus == .connected || session.sessionConnectionStatus == .connecting || session.sessionConnectionStatus == .disconnecting) {
            endCall(self)
        }
    }
    
    @objc private func handleScreenTap(_ notification: UITapGestureRecognizer) {
        if shouldShowCallTimer {
            callProgressLabel.isHidden = false
            callProgressBar.isHidden = false
            recordingLabel.isHidden = false
        }
        
        if self.btnEndCall.alpha == 0 {
            UIView.animate(withDuration: 0.25, delay: 0.0, options: [.curveEaseIn, .allowUserInteraction], animations: {
                self.btnEndCall.alpha = 1.0
                self.callProgressLabel.alpha = 1.0
                self.callProgressBar.alpha = 1.0
                self.recordingLabel.alpha = 1.0
            }) { (_) in
                self.hideButton()
            }
        }
    }
    
    private func hideButton() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            UIView.animate(withDuration: 0.8, delay: 0.0, options: [.curveEaseIn, .allowUserInteraction], animations: {
                self.btnEndCall.alpha = 0.0
                self.callProgressLabel.alpha = 0.0
                self.callProgressBar.alpha = 0.0
                self.recordingLabel.alpha = 0.0
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
        print("~>session id: \(kSessionId)")
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
        
        let random = arc4random() % 5000
        room = "\(myID)+\(friendID)+\(random)"
        
        print("~>Random: \(random)")
        
//        let room = "\(myID)+\(friendID)"
        guard let url = URL(string: "\(Server.baseURL)\(Server.room)/\(room)") else {
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
//        let myID = myUser.id, let friendID = friend.id
        guard !room.isEmpty else {
            self.showCallErrorAlert()
            return
        }
        print("~>Setting up for room: \(room)")
//        room = "\(friendID)+\(myID)"
        guard let url = URL(string: "\(Server.baseURL)\(Server.room)/\(room)") else {
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
                print("~>Got an api key: \(self.kApiKey)")
                
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
        let usersRef = Database.database().reference().child(FirebaseStructure.usersLocation)
        
        if status == .outgoing {
            myCall = Call(sessionID: id, status: .outgoing, from: friend.id!, in: room)
            friendCall = Call(sessionID: id, status: .incoming, from: myUser.id!, in: room)
        } else {
            myCall = Call(sessionID: id, status: .connected, from: friend.id!, in: room)
            friendCall = Call(sessionID: id, status: .connected, from: myUser.id!, in: room)
        }
        
        
        // encode data
        let myCallData = myCall.toAny()
        let friendCallData = friendCall.toAny()
        // upload to firebase
        usersRef.child(self.friend.id!).child(FirebaseStructure.CharmUser.currentCallLocation).setValue(friendCallData)
        usersRef.child(self.myUser.id!).child(FirebaseStructure.CharmUser.currentCallLocation).setValue(myCallData)
        
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
        
        publisher.publishAudio = true
        publisher.publishVideo = true
        
        if let sub = subscriber {
            sub.subscribeToAudio = true
            sub.subscribeToVideo = true
        }
        
        session.publish(publisher, error: &error)
        
        if let pubView = publisher.view {
            pubView.frame = CGRect(x: 20, y: 60, width: kMyScreenWidth, height: kMyScreenHeight)
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
        publisher.publishAudio = true
        publisher.publishVideo = true
        
        if let sub = subscriber {
            sub.subscribeToAudio = true
            sub.subscribeToVideo = true
        }
        
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
        DispatchQueue.main.async {
            let fullURL = "\(Server.baseURL)\(Server.archive)\(Server.startArchive)"
            let url = URL(string: fullURL)
            var urlRequest: URLRequest? = nil
            if let url = url {
                urlRequest = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10)
            }
            
            guard var request = urlRequest else { return }
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            let dict = [
                "sessionId": self.kSessionId,
                "userId" : self.myUser.id!
            ]
            request.httpBody = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
            
            let configuration = URLSessionConfiguration.default
            let session = URLSession(configuration: configuration)
            
            let dataTask = session.dataTask(with: request) { (data, response, error) in
                if let error = error {
                    print("~>Got an error trying to start an archive: \(error)")
                } else {
                    if self.isInitiatingUser {
                        self.pendingArchive = SessionArchive(id: self.kSessionId, callerId: self.myUser.id!, calledId: self.friend.id!, callerName: self.myUser.userProfile.firstName, calledName: self.friend.firstName)
                    } else {
                        print("~>No need to upload to pending twice.")
                    }
                }
            }
            
            dataTask.resume()
            session.finishTasksAndInvalidate()
        }
    }

    func stopArchive() {
        
        guard !archiveHasBeenStopped else { return }
        
        let fullURL = "\(Server.baseURL)\(Server.archive)/\(archiveId)\(Server.stopArchive)"
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
        if !userInitiatedDisconnect { userInitiatedDisconnect = true }
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
            let usersRef = Database.database().reference().child(FirebaseStructure.usersLocation)
            usersRef.child(myUser.id!).child(FirebaseStructure.CharmUser.currentCallLocation).removeValue()
            usersRef.child(friend.id!).child(FirebaseStructure.CharmUser.currentCallLocation).removeValue()
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
        var error: OTError?
        session.unpublish(publisher, error: &error)
        if let sub = subscriber {
            session.unsubscribe(sub, error: &error)
        }
        
        if let error = error {
            print("~>Unpublish error: \(error)")
        }
        DispatchQueue.global(qos: .utility).async {
            // remove call
            Database.database().reference().child(FirebaseStructure.usersLocation).child(self.myUser.id!).child(FirebaseStructure.CharmUser.currentCallLocation).removeValue()
        }
    }
    
    func session(_ session: OTSession, streamCreated stream: OTStream) {
        print("~>Session streamCreated: \(stream.streamId)")
        print("~>Stream has audio: \(stream.hasAudio)")
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
    
    func session(_ session: OTSession, connectionDestroyed connection: OTConnection) {
        print("~>Connection destroyed.")
        if !userInitiatedDisconnect {
            let disconnectAlert = UIAlertController(title: "Call Ended", message: "\(friend.firstName) left the call.", preferredStyle: .alert)
            disconnectAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                self.endCall(self.btnEndCall as Any)
            }))
            present(disconnectAlert, animated: true, completion: nil)
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
            
            switch self.isInitiatingUser {
            case true:
                print("~>Should be taking away a token.")
                self.myUser.userProfile.numCredits -= 1
                let tokens = self.myUser.userProfile.numCredits < 0 ? 0 : self.myUser.userProfile.numCredits
                DispatchQueue.global(qos: .utility).async {
                    Database.database().reference().child(FirebaseStructure.usersLocation).child(self.myUser.id!).child(FirebaseStructure.CharmUser.profileLocation).child(FirebaseStructure.CharmUser.UserProfile.numCredits).setValue(tokens)
                }
                
                if self.pendingArchive != nil {
                    print("~>Setting archive to complete")
                    self.pendingArchive?.setArchiveComplete()
                }
            case false:
                print("~>Not the initiating user.")
            }
            
            self.useTokenTimer.invalidate()
        })
        
        endArchiveTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(requiredCallTime), repeats: false, block: { (_) in
            self.stopArchive()
            self.archiveHasBeenStopped = true
            self.endArchiveTimer.invalidate()
        })
        
        shouldShowCallTimer = true
        handleScreenTap(UITapGestureRecognizer())
        
        callTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (_) in
            self.callTime += 1
            
            let progress = Float(self.callTime) / Float(self.requiredCallTime)
            
            self.callProgressBar.progress = progress
            self.callProgressLabel.text = String(format:"%.0f", (progress * 100)) + "%"
            
            
//            let minutes = self.callTime / 60
//            let seconds = self.callTime % 60
//
//            let minString = String(format: "%02d", minutes)
//            let secString = String(format: "%02d", seconds)
//
//            let timeString = "\(minString):\(secString)"
            
           // self.lblCallTimer.text = timeString
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
