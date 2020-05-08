//
//  LearningVideoViewModel.swift
//  Charm
//
//  Created by Daniel Pratt on 3/14/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit
import Firebase

class TutorialManager: NSObject {
    
    // delegate for updating table view
    var delegate: TableViewRefreshDelegate? = nil
    
    var sections: VideoSections!
    
    var numSections: Int {
        return sections?.sections.count ?? 0
    }
    
    var isLoading: Bool = false {
        didSet {
            delegate?.showActivity(isLoading)
        }
    }
    
    static var shared = TutorialManager()
    
    // MARK: - Class Init
    
    override init() {
        super.init()
        loadVideos()
    }
    
    // MARK: - TableView Functions
    
    func rows(inSection section: Int) -> Int {
        return sections.sections[section].videos.count
    }
    
    func configure(cell: TutorialCell, forIndexPath indexPath: IndexPath) -> TutorialCell {
        let video: LearningVideo = sections.sections[indexPath.section].videos[indexPath.row]
        
        let lessonNumber = indexPath.row + 1
        let lesson = "Lesson \(lessonNumber)"
        cell.lessonNumberLabel.text = lesson
        cell.lessonTitleLabel.text = video.title
        
        if cell.thumbnailImageView.image == nil {
            if let image = video.thumbnailImage {
                print("~>There is already an image.")
                cell.thumbnailImageView.image = image
            } else {
                video.getThumbnailImage { (image) in
                    cell.thumbnailImageView.image = image
                }
            }
        }
        return cell
    }
    
    // MARK: - Private Helper Functions
    
    // Load video files
    private func loadVideos() {
        isLoading = true
        let learningRef = Database.database().reference().child(FirebaseStructure.Videos.learning).child(FirebaseStructure.Videos.sections)

        learningRef.observe(.value) { (snapshot) in
            do {
                self.sections = try VideoSections(snapshot: snapshot)
                self.delegate?.updateTableView()
                self.isLoading = false
                if self.sections.sections.count == 0 {
                    self.showInternetConnectionAlert()
                }
            } catch let error {
                print("~>There was an error decoding the video section: \(error)")
                self.delegate?.updateTableView()
                self.isLoading = false
                self.showInternetConnectionAlert()
            }
        }
    }
    
    private func showInternetConnectionAlert() {
        DispatchQueue.main.async {
            let navVC = (UIApplication.shared.delegate as? AppDelegate)?.window?.rootViewController as? UINavigationController
            guard let nav = navVC else { return }
            
            let alert = UIAlertController(title: "Check Your Connection", message: "Charm is unable to communicate with the server, please check your internet connection and try again.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            nav.present(alert, animated: true, completion: nil)
        }
    }
}
