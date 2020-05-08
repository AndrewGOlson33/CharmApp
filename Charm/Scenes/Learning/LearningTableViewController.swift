//
//  LearningTableViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 3/14/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit
import AVKit
import Firebase

class LearningTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var charmLevelLabel: UILabel!
    
    let viewModel = TutorialManager.shared
    
    let activityView = UIActivityIndicatorView()

    override func viewDidLoad() {
        super.viewDidLoad()

        // enable view model to reload table view data
        viewModel.delegate = self
        
        tableView.tableFooterView = UIView()
        
        // setup activity view
        
        if #available(iOS 13.0, *) {
            activityView.style = .large
        } else {
            activityView.style = .whiteLarge
        }
        
        activityView.hidesWhenStopped = true
        view.addSubview(activityView)
        
        // Position it at the center of the ViewController.
        activityView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityView.centerYAnchor.constraint(equalTo: view.centerYAnchor)])
        
        showActivity(viewModel.isLoading)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        charmLevelLabel.text = "Charm \(ConversationManager.shared.levelDetail ?? "Error :(")"
        progressBar.progress = Float(ConversationManager.shared.progress)
    }
    
    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numSections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.rows(inSection: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TutorialCell", for: indexPath) as! TutorialCell
        return viewModel.configure(cell: cell, forIndexPath: indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 156.0
    }
    
    // play video
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let urlString = viewModel.sections.sections[indexPath.section].videos[indexPath.row].url
        let avPlayerVC = AVPlayerViewController()
        let videoStorage = Storage.storage()
        videoStorage.reference(forURL: urlString).downloadURL { (url, error) in
            if let url = url {
                let player = AVPlayer(url: url)
                avPlayerVC.player = player
                self.navigationController?.pushViewController(avPlayerVC, animated: true)
                // start playing the video as soon as it loads
                avPlayerVC.player?.play()
            } else if let error = error {
                print("~>Unable to get storage url: \(error)")
                return
            } else {
                // this should never happen
                print("~>An unknown error has occured.")
            }
        }
    }
}

extension LearningTableViewController: TableViewRefreshDelegate {
    func updateTableView() {
        tableView.reloadData()
        tableView.layoutSubviews()
    }
    
    func showActivity(_ animating: Bool) {
        if animating {
            activityView.startAnimating()
        } else {
            activityView.stopAnimating()
        }
    }
}
