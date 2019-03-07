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
    
    // MARK: - IBOutlets
    
    // MARK: - Properties
    
    // User to establish connection with
    var friend: Friend! = nil
    
    // Session Variables
    var session: OTSession?
    var publisher: OTPublisher?
    var subscriber: OTSubscriber?
    
    // OpenTok API key
    var kApiKey = TokBox.ApiKey
    // Generated session ID
    var kSessionId = ""
    // Generated token
    var kToken = ""
    
    // MARK: - View Lifecycle Functions

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        guard let id = appDelegate.user.id else { return }
        let room = ("\(id)+\(friend.id!)")
        let url = URL(string: "https://charmcharismaanalytics.herokuapp.com/room/\(room)")
        let dataTask = session.dataTask(with: url!) {
            (data: Data?, response: URLResponse?, error: Error?) in
            
            guard error == nil, let data = data else {
                print("~>Got an error: \(error!)")
                return
            }
            
            print(data)
            
            let dict = try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [AnyHashable: Any]
            self.kApiKey = dict?["apiKey"] as? String ?? ""
            self.kSessionId = dict?["sessionId"] as? String ?? ""
            self.kToken = dict?["token"] as? String ?? ""
            print("~>Got an apiKey: \(self.kApiKey)")
            print("~>Got a sessionid: \(self.kSessionId)")
            print("~>Got a token: \(self.kToken)")
            self.connectToAnOpenTokSession()
        }
        dataTask.resume()
        session.finishTasksAndInvalidate()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        endCallButtonTapped(self)
    }

    // MARK: - Button Handling
    
    @IBAction func endCallButtonTapped(_ sender: Any) {
        var error: OTError? = nil
        session?.disconnect(&error)
        if let error = error {
            print("~>There was an error: \(error)")
            if let _ = sender as? UIButton {
                navigationController?.popViewController(animated: true)
            }
        } else {
            print("~>Successfully disconnected.")
        }
        
        
    }
    
    func connectToAnOpenTokSession() {
        session = OTSession(apiKey: kApiKey, sessionId: kSessionId, delegate: self)
        var error: OTError?
        session?.connect(withToken: kToken, error: &error)
        if error != nil {
            print(error!)
        }
    }

}

// MARK: - OTSessionDelegate callbacks
extension VideoCallViewController: OTSessionDelegate {
    
    func sessionDidConnect(_ session: OTSession) {
        print("~>The client connected to the OpenTok session.")
        let settings = OTPublisherSettings()
        settings.name = UIDevice.current.name
        
        guard let publisher = OTPublisher(delegate: self as? OTPublisherKitDelegate, settings: settings) else {
            return
        }
        
        var error: OTError?
        session.publish(publisher, error: &error)
        guard error == nil else {
            print(error!)
            return
        }
        
        guard let publisherView = publisher.view else {
            return
        }
        
        publisher.publishVideo = true
        publisher.publishAudio = true
        
        view.addSubview(publisherView)
        view.sendSubviewToBack(publisherView)
        
        publisherView.translatesAutoresizingMaskIntoConstraints = false
        let horizontalConstraint = NSLayoutConstraint(item: publisherView, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant: 0)
        let verticalConstraint = NSLayoutConstraint(item: publisherView, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: publisherView, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: view.frame.width)
        let heightConstraint = NSLayoutConstraint(item: publisherView, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: view.frame.height)
         view.addConstraints([horizontalConstraint, verticalConstraint, widthConstraint, heightConstraint])
    }
    
    func sessionDidDisconnect(_ session: OTSession) {
        print("The client disconnected from the OpenTok session.")
    }
    
    func session(_ session: OTSession, didFailWithError error: OTError) {
        print("The client failed to connect to the OpenTok session: \(error).")
    }
    func session(_ session: OTSession, streamCreated stream: OTStream) {
        print("~>A stream was created in the session.")
        subscriber = OTSubscriber(stream: stream, delegate: self)
        guard let subscriber = subscriber else {
            return
        }
        
        var error: OTError?
        session.subscribe(subscriber, error: &error)
        guard error == nil else {
            print("~>Error subscribing to session: \(String(describing: error))")
            return
        }
        
        guard let subscriberView = subscriber.view else {
            return
        }
        
        subscriberView.frame = UIScreen.main.bounds
        view.insertSubview(subscriberView, at: 0)
    }
    
    func session(_ session: OTSession, streamDestroyed stream: OTStream) {
        print("A stream was destroyed in the session.")
    }
}

extension VideoCallViewController: OTSubscriberKitDelegate {
    
    public func subscriberDidConnect(toStream subscriber: OTSubscriberKit) {
        print("~>The subscriber did connect to the stream.")
    }
    
    public func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {
        print("~>The subscriber failed to connect to the stream.")
    }
    
    func subscriberDidDisconnect(fromStream subscriber: OTSubscriberKit) {
        print("~>The subscriber did disconnect from the stream.")
    }
    
}
