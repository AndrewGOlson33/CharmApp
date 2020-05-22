//
//  SnapshotsListTableViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 3/26/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit

class SnapshotsListTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
     // MARK: - IBOutlets
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var charmLevelLabel: UILabel!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
     // MARK: -  Properties
    
    var snapshots: [Snapshot] {
        return FirebaseModel.shared.snapshots
    }
    
    let dFormatter = DateFormatter()

     // MARK: - Lifecycle
    
    override func viewDidLoad() {
        NotificationCenter.default.addObserver(self, selector: #selector(snapshotLoaded), name: FirebaseNotification.SnapshotLoaded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(snapshotLoaded), name: FirebaseNotification.SnapshotLoadFailed, object: nil)
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if SnapshotsLoading.shared.isLoading {
            spinner.startAnimating()
        }
        
        charmLevelLabel.text = "Charm \(ConversationManager.shared.levelDetail ?? "Error :(")"
        progressBar.progress = Float(ConversationManager.shared.progress)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !didShowSampleAlert {
            showSampleAlert()
            didShowSampleAlert = true
        }
    }
    
    // MARK: - Methods
    
    @objc private func snapshotLoaded() {
        spinner.stopAnimating()
        tableView.reloadData()
    }
    
    @objc private func snapshotLoadFailed() {
        // Loading failed
        spinner.stopAnimating()
        let navVC = (UIApplication.shared.delegate as! AppDelegate).window!.rootViewController as! UINavigationController
        let alert = UIAlertController(title: "Error", message: "Unable to load call snapshots, please try again.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        navVC.present(alert, animated: true, completion: nil)
    }
    
    fileprivate func getSummaryValues(from value: Double) -> (score: Double, percent: Double, rawValue: Double) {
        return (score: value / 10, percent: value / 10, rawValue: value)
    }
    
    private func showSampleAlert() {
        print("load json snapshot data")
        let noSnapshotsAlert = UIAlertController(title: "Explore Sample Snapshot", message: "Here you can view your conversation metrics.\n\nYour metrics are scored by our servers, and are based on the speaking styles of the world's most charming people.\n\nYou can generate metrics by calling a friend.  It takes our servers about 15 minutes to process your metrics after your call has completed.", preferredStyle: .alert)
        noSnapshotsAlert.addAction(UIAlertAction(title: "View Sample Snapshot", style: .default, handler:{ (_) in
        }))
        present(noSnapshotsAlert, animated: true, completion: nil)
    }
    
    

    // MARK: - Table view data source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return snapshots.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SnapshotCell", for: indexPath) as! SnapshotCell

        let snapshot = snapshots[indexPath.row]
        
        let dateString = snapshot.friendlyDateString.isEmpty ? "" : "On " + snapshot.friendlyDateString
        cell.nameLabel.text = snapshot.friend
        cell.dateLabel.text = dateString
        
        cell.profileImageView.image = UIImage.generateImageWithInitials(initials: String(snapshot.friend.first!))
        
        let ideaEngagement = getSummaryValues(from: snapshot.getTopLevelScoreValue(forSummaryItem: .ideaEngagement) ?? 0)
        let conversationEngagement = getSummaryValues(from: snapshot.getTopLevelScoreValue(forSummaryItem: .conversationEngagement) ?? 0)
        let personalConnection = getSummaryValues(from: snapshot.getTopLevelScoreValue(forSummaryItem: .personalConnection) ?? 0)
        let emotionalConnection = getSummaryValues(from: snapshot.getTopLevelScoreValue(forSummaryItem: .emotionalConnection) ?? 0)
        
        cell.ideaClarityProgressBar.progress = Float(ideaEngagement.percent)
        cell.conversationFlowProgressBar.progress = Float(conversationEngagement.percent)
        cell.personalBondProgressBar.progress = Float(personalConnection.percent)
        cell.emotionsProgressBar.progress = Float(emotionalConnection.percent)
        
        
        cell.ideaClarityProgressLabel.text = "\(Int(ideaEngagement.score * 100))%"
        cell.conversationFlowProgressLabel.text = "\(Int(conversationEngagement.score * 100))%"
        cell.personalBondProgressLabel.text = "\(Int(personalConnection.score * 100))%"
        cell.emotionsProgressLabel.text = "\(Int(emotionalConnection.score * 100))%"
        

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let snapshot = snapshots[indexPath.row]
        FirebaseModel.shared.selectedSnapshot = snapshot
        performSegue(withIdentifier: "showSnapshotDetails", sender: self)
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 270.0
    }

    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }
    
}
