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
    
    let viewModel = LearningVideoViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        // enable view model to reload table view data
        viewModel.delegate = self
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numSections
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.rows(inSection: section)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellID.VideoList, for: indexPath)
        
        return viewModel.configure(cell: cell, forIndexPath: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.sections.sections[section].sectionTitle
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

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

}

extension LearningTableViewController: TableViewRefreshDelegate {
    
    func updateTableView() {
        tableView.reloadData()
    }
    
}
