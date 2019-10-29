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

class LearningTableViewController: UITableViewController {
    
    let viewModel = LearningVideoViewModel.shared
    
    let activityView = UIActivityIndicatorView()

    override func viewDidLoad() {
        super.viewDidLoad()

        // enable view model to reload table view data
        viewModel.delegate = self
        
        // setup activity view
        
        if #available(iOS 13.0, *) {
            activityView.style = .large
            activityView.color = .label
        } else {
            activityView.style = .whiteLarge
            activityView.color = .black
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

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numSections
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.rows(inSection: section)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellID.videoList, for: indexPath) as! VideoTableViewCell
        
        return viewModel.configure(cell: cell, forIndexPath: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.sections.sections[section].sectionTitle
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else  { return }
        header.textLabel?.font = UIFont.boldSystemFont(ofSize: 24)
    }
    
    // play video
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
    
    // prevent extra table view lines
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(origin: .zero, size: CGSize(width: tableView.frame.width, height: 1)))
        view.backgroundColor = .clear
        return view
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }

}

extension LearningTableViewController: TableViewRefreshDelegate {
    
    func updateTableView() {
        tableView.reloadData()
    }
    
    func showActivity(_ animating: Bool) {
        
    }
    
}
