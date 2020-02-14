//
//  InfoDetailViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 7/8/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit
import WebKit

enum InfoDetail: String {
    case emotions = "https://www.charismaanalytics.com/emotional-connection-tutorial"
    case conversation = "https://www.charismaanalytics.com/conversation-engagement-tutorial"
    case ideas = "https://www.charismaanalytics.com/idea-engagement-tutorial"
    case connection = "https://www.charismaanalytics.com/personal-connection-tutorial"
}

class InfoDetailViewController: UIViewController {
    
    // MARK: - Tutorial Views
    
    // old tutorial text views
    @IBOutlet weak var txtEmotions: UITextView!
    @IBOutlet weak var txtConversation: UITextView!
    @IBOutlet weak var txtIdeas: UITextView!
    @IBOutlet weak var txtConnection: UITextView!
    
    // new tutorial web view
    
    @IBOutlet weak var viewWeb: WKWebView!
    @IBOutlet weak var viewActivity: UIActivityIndicatorView!
    
    // MARK: - Properties
    
    var type: InfoDetail? = nil
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add action to navigation bar
        
        let button = UIBarButtonItem(title: "Get Support", style: .plain, target: self, action: #selector(showSupport))
        self.navigationItem.rightBarButtonItem = button
        
        // make sure everythign is hidden
        txtEmotions.isHidden = true
        txtConversation.isHidden = true
        txtIdeas.isHidden = true
        txtConnection.isHidden = true
        
        // setup webview delegate
        viewWeb.navigationDelegate = self
        viewWeb.allowsBackForwardNavigationGestures = false
        
        // make sure the detail type has been set, otherwise go back
        guard let detail = type else {
            tabBarController?.navigationController?.popViewController(animated: true)
            return
        }
        
        var title = "More Information"
        
        switch detail {
        case .conversation:
            title = "Conversation"
        case .connection:
            title = "Connection"
        case .emotions:
            title = "Emotions"
        case .ideas:
            title = "Ideas"
        }
        
        navigationItem.title = title
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadWeb()
    }
    
    private func loadWeb() {
        guard let detail = type, let url = URL(string: detail.rawValue) else { fatalError("~>Unable to load type or url.") }
        let request = URLRequest(url: url, cachePolicy: .reloadRevalidatingCacheData, timeoutInterval: 30.0)
        viewWeb.load(request)
    }
    
    @objc private func showSupport() {
        performSegue(withIdentifier: SegueID.submitFeedback, sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == SegueID.submitFeedback, let vc = segue.destination as? SendFeedbackViewController else { return }
        vc.titleString = "Enter Question"
    }
}

extension InfoDetailViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        DispatchQueue.main.async {
            print("~>Start load")
            self.viewActivity.startAnimating()
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.viewActivity.stopAnimating()
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.async {
            self.viewActivity.stopAnimating()
            
            print("~>Failed with an error: \(error)")
            let nserror = error as NSError
            
            let alert = UIAlertController(title: "Connection Error", message: "An unknown error has occured.  If this continues, please contact us through the leave feedback option on the settings page.", preferredStyle: .alert)
            
            if nserror.code == -1009 {
                // handle no network
                alert.message = "You are not connected to the internet. Please check your internet connection, and then try again."
            }
            
            if nserror.code == -1001 {
                // handle timeout
                alert.message = "The request timed out. Please check your internet connection and try again."
            }
            
            if nserror.code == -1004 {
                // handle bad server
                alert.message = "The server appears to be down. Check back later. If the issue persists, please contact us through the leave feedback option on the settings page."
            }
            
            if alert.message != "An unknown error has occured.  If this continues, please contact us through the leave feedback option on the settings page." {
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
}
