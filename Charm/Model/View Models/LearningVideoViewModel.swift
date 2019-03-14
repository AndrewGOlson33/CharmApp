//
//  LearningVideoViewModel.swift
//  Charm
//
//  Created by Daniel Pratt on 3/14/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

class LearningVideoViewModel: NSObject {
    
    // delegate for updating table view
    var delegate: TableViewRefreshDelegate? = nil
    
    var sections: VideoSections!
    
    var numSections: Int {
        return sections?.sections.count ?? 0
    }
    
    // MARK: - Class Init
    
    override init() {
        super.init()
        loadVideos()
    }
    
    // MARK: - TableView Functions
    
    func rows(inSection section: Int) -> Int {
        return sections.sections[section].videos.count
    }
    
    func configure(cell: UITableViewCell, forIndexPath indexPath: IndexPath) -> UITableViewCell {
        let video: LearningVideo = sections.sections[indexPath.section].videos[indexPath.row]
        
        let lessonNumber = indexPath.row + 1
        let lesson = "Lesson \(lessonNumber)"
        cell.textLabel?.text = "\(lesson) - \(video.title)"
        return cell
    }
    
    // MARK: - Private Helper Functions
    
    // Load video files
    fileprivate func loadVideos() {
        // get database references
        let learningRef = Database.database().reference().child(FirebaseStructure.Videos.Learning)
        
        learningRef.observeSingleEvent(of: .value) { (snapshot) in
            guard let value = snapshot.value else { return }
            
            do {
                self.sections = try FirebaseDecoder().decode(VideoSections.self, from: value)
                self.delegate?.updateTableView()
            } catch let error {
                print("~>There was an error decoding the video section: \(error)")
                print("~>Value: \(String(describing: value))")
            }
        }
    }
    
}
