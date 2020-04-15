//
//  OnboardingVideoLayerViewController.swift
//  Charm
//
//  Created by Игорь on 15.0420..
//  Copyright © 2020 Charm, LLC. All rights reserved.
//

import UIKit
import AVKit

class OnboardingVideoLayerViewController: UIViewController {
    
    var player: AVPlayer?
    var videoURl: String?
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var videoViewContainer: UIView!
    
    override func viewDidLoad() {
         super.viewDidLoad()
         initializeVideoPlayerWithVideo()
     }

     func initializeVideoPlayerWithVideo() {

         // get the path string for the video from assets
         let videoString:String? = videoURl
         guard let unwrappedVideoPath = videoString else {return}

         // convert the path string to a url
         let videoUrl = URL(fileURLWithPath: unwrappedVideoPath)

         // initialize the video player with the url
         self.player = AVPlayer(url: videoUrl)

         // create a video layer for the player
         let layer: AVPlayerLayer = AVPlayerLayer(player: player)

         // make the layer the same size as the container view
         layer.frame = videoViewContainer.bounds

         // make the video fill the layer as much as possible while keeping its aspect size
        layer.videoGravity = .resizeAspectFill

         // add the layer to the container view
         videoViewContainer.layer.addSublayer(layer)
     }

     @IBAction func playVideoButtonTapped(_ sender: UIButton) {
         // play the video if the player is initialized
         player?.play()
        sender.isHidden = true
     }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        player?.pause()
        playButton.isHidden = false
    }
    
}
