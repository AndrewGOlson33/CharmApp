//
//  OnboardingViewController.swift
//  Charm
//
//  Created by Игорь on 15.0420..
//  Copyright © 2020 Charm, LLC. All rights reserved.
//

import UIKit
import UPCarouselFlowLayout
import AVKit

class OnboardingViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var pageControl: UIPageControl!
    
    // MARK: - Properties
    
    private var dataSource: [OnboardingItem] = [
        OnboardingItem(title: "Sharpen Your Skills", descritpion: "Reply to everyday phrases with you favorite influencer.", image: UIImage(named: "WELCOME-BACKGROUND"), videoURL: nil),
        OnboardingItem(title: "Visualize Your Conversations", descritpion: "See where you engaged their mind and created a connection", image: UIImage(named: "WELCOME-BACKGROUND"), videoURL: nil),
        OnboardingItem(title: "Meet Charming New People", descritpion: "Match with other users based on your unique conversation data", image: nil, videoURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")
    ]
    
    private var currentIndex: Int = 0
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupUI()
    }
    
    // MARK: - Methods
    
    private func setupUI() {
        let layout = UPCarouselFlowLayout()
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width - 60, height: UIScreen.main.bounds.height * 0.55)
        layout.scrollDirection = .horizontal
        layout.sideItemAlpha = 0.9
        layout.sideItemScale = 0.9
        layout.spacingMode = .fixed(spacing: 20)
        collectionView.collectionViewLayout = layout
        
        pageControl.numberOfPages = dataSource.count
        pageControl.currentPage = 0
        
        titleLabel.text = dataSource.first?.title
        descriptionLabel.text = dataSource.first?.description
        
        collectionView.reloadData()
    }
    
    private func changeText(for index: Int) {
        let item = dataSource[index]
        UIView.animate(withDuration: 0.15) {
            self.titleLabel.text = item.title
            self.descriptionLabel.text = item.description
        }
    }
    
    private func showSubscriptionSelection() {
        performSegue(withIdentifier: SegueID.subscriptions, sender: nil)
    }
    
    // MARK: - IBActions
    
    @IBAction func next(_ sender: UIButton) {
        showSubscriptionSelection()
//        currentIndex += 1
//        collectionView.scrollToItem(at: IndexPath.init(row: currentIndex, section: 0), at: .centeredHorizontally, animated: true)
//        changeText(for: currentIndex)
    }



}


extension OnboardingViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OnboardingCell", for: indexPath) as! OnboardingCell
        
        let item = dataSource[indexPath.row]
        
        if let videoURL = item.videoURL {
            cell.imageView.isHidden = true
            cell.contrainerView.isHidden = false
            ViewEmbedder.embedVideoVC(with: videoURL, parent: self, container: cell.contrainerView)
        } else {
            cell.imageView.image = item.image
        }
        
        
        return cell
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let index = Int(scrollView.contentOffset.x / (scrollView.bounds.size.width - 60.0))
        pageControl.currentPage = index
        changeText(for: index)
        currentIndex = index
    }
    
}
