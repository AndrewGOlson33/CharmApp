//
//  VideoCallViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 3/7/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit
import OpenTok

class VideoCallViewController: UIViewController {
    
    // MARK: - Properties
    
    // User to establish connection with
    var friend: Friend! = nil
    
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
    var kApiKey = TokBox.ApiKey
    
    // TODO: - replace these with real values
    // Generated session ID
    var kSessionId = "1_MX40NjIzMjg2Mn5-MTU1MTk5MTA3NzUwMX5JM2VyOEN3QUFIeklRUUVIbFRSeWhVNVR-fg"
    // Generated token
    var kToken = "T1==cGFydG5lcl9pZD00NjIzMjg2MiZzaWc9ZWNlODY4MWJhYzFjYjY4MjdkY2Y0NjM2YzAyOWU3N2I1ZjY3MTY3MjpzZXNzaW9uX2lkPTFfTVg0ME5qSXpNamcyTW41LU1UVTFNVGs1TVRBM056VXdNWDVKTTJWeU9FTjNRVUZJZWtsUlVVVkliRlJTZVdoVk5WUi1mZyZjcmVhdGVfdGltZT0xNTUxOTkxMDc4Jm5vbmNlPTAuODIwNTU1MDc3OTQwNDM4NyZyb2xlPXB1Ymxpc2hlciZleHBpcmVfdGltZT0xNTUyMDc3NDc4JmluaXRpYWxfbGF5b3V0X2NsYXNzX2xpc3Q9"
    
    // Picture in Picture width / height
    let kWidgetHeight = 240
    let kWidgetWidth = 320
    
    // MARK: - View Lifecycle Functions

    override func viewDidLoad() {
        super.viewDidLoad()
        
        doConnect()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        endCallButtonTapped(self)
    }
    
    // MARK: - Private Helper Functions
    
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
            pubView.frame = CGRect(x: 0, y: 0, width: kWidgetWidth, height: kWidgetHeight)
            view.addSubview(pubView)
        }
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

    // MARK: - Button Handling
    
    @IBAction func endCallButtonTapped(_ sender: Any) {
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
            subsView.frame = CGRect(x: 0, y: kWidgetHeight, width: kWidgetWidth, height: kWidgetHeight)
            view.addSubview(subsView)
            view.bringSubviewToFront(subsView)
        }
    }
    
    func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {
        print("~>Subscriber failed: \(error.localizedDescription)")
    }
}
