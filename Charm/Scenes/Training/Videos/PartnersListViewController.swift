//
//  PartnersListViewController.swift
//  Charm
//
//  Created by Игорь on 19.0520..
//  Copyright © 2020 Charm, LLC. All rights reserved.
//

import UIKit

class PartnersListViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var charmLevelLabel: UILabel!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    // MARK: - Properties
    
    private var canStartPractice = false
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        setupNotifications()
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        spinner.startAnimating()
        PracticeVideoManager.shared.getListOfFiles()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        charmLevelLabel.text = "Charm \(ConversationManager.shared.levelDetail ?? "Error :(")"
        progressBar.progress = Float(ConversationManager.shared.progress)

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Methods
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(dataDidLoaded), name: FirebaseNotification.trainingModelLoaded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(dataDidFailedToLoad), name: FirebaseNotification.trainingModelFailedToLoad, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(videosDidLoaded), name: FirebaseNotification.didUpdatePracticeVideos, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(videosdFailedToLoad), name: FirebaseNotification.didFailToUpdatePracticeVideos, object: nil)
    }
    
    @objc private func dataDidLoaded() {
        spinner.stopAnimating()
        canStartPractice = true
    }
    
    @objc private func dataDidFailedToLoad() {
        spinner.stopAnimating()
        showAlert(title: "Error", message: "Failed to load data :(")
    }
    
    @objc private func videosDidLoaded() {
        tableView.reloadData()
        spinner.stopAnimating()
    }
    
    @objc private func videosdFailedToLoad() {
        spinner.stopAnimating()
        showAlert(title: "Error", message: "Failed to load data :(")
    }
    
    fileprivate func showAlert(title: String, message: String) {
        // setup views for displaying error alerts
        let navVC = (UIApplication.shared.delegate as! AppDelegate).window!.rootViewController as! UINavigationController
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Try again", style: .default, handler: { (_) in
            self.spinner.startAnimating()
            PracticeVideoManager.shared.getListOfFiles()
        }))
        navVC.present(alert, animated: true, completion: nil)
    }
    
    fileprivate func showInfoAlert(title: String, message: String) {
        // setup views for displaying error alerts
        let navVC = (UIApplication.shared.delegate as! AppDelegate).window!.rootViewController as! UINavigationController
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        navVC.present(alert, animated: true, completion: nil)
    }

}


extension PartnersListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return PracticeVideoManager.shared.partners.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PracticeVideoCell", for: indexPath) as! PracticeVideoCell
        let partner = PracticeVideoManager.shared.partners[indexPath.row]
        cell.nameLabel.text = partner.name
        cell.thumbnailImageView.image = UIImage(named: partner.name)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 140.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if canStartPractice {
            let partner = PracticeVideoManager.shared.partners[indexPath.row]
            // Show videos
            guard let vc = storyboard?.instantiateViewController(withIdentifier: "PracticeVideoViewController") as? PracticeVideoViewController else { return }
            vc.partner = partner
            present(vc, animated: true, completion: nil)
        } else {
            showInfoAlert(title: "Loading data..", message: "Loading training data, please wait a moment.")
        }
    }
    
}
