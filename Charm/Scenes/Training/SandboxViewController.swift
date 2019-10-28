//
//  SandboxViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 3/25/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit
import Speech
import AVKit
import Firebase

class SandboxViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var scoresTableView: UITableView!
    @IBOutlet weak var txtReply: UITextView!
    @IBOutlet weak var btnRecordStop: UIButton!
    @IBOutlet weak var btnScoreReset: UIButton!
//    @IBOutlet weak var btnRecordStop: UIImageView!
//    @IBOutlet weak var btnScoreReset: UIImageView!
    
    // MARK: - Properties
    
    // View Model
//    let viewModel = ScorePhraseModel()
//    var speechModel: SpeechRecognitionModel = SpeechRecognitionModel()
//    
//    // arrays for drawing table view
//    var averageSliderInfo: [SliderCellInfo] = []
//    var lastSliderInfo: [SliderCellInfo] = []
//    
//    // Helps deal with layout glitches caused by highcharts
//    var chartDidLoad: Bool = false
//    
//    // Detect if we are in score or reset mode
//    private var shouldReset = false
//    
//    // Button Images
//    
//    let mic = UIImage(named: Image.mic)!
//    let stop = UIImage(named: Image.stop)!
//    let chart = UIImage(named: Image.update)!
//    let reset = UIImage(named: Image.reset)!
//    
//    var viewHasAppeared: Bool = false
//    
//    // MARK: - View Lifecycle
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        // setup text view
//        txtReply.delegate = self
//        txtReply.textColor = .lightGray
//        txtReply.text = "tap microphone and start speaking"
//        
//        // Setup Button Taps
//        
////        let recordStopTap = UITapGestureRecognizer(target: self, action: #selector(recordButtonTapped(_:)))
////        recordStopTap.numberOfTapsRequired = 1
////        recordStopTap.numberOfTouchesRequired = 1
////        btnRecordStop.addGestureRecognizer(recordStopTap)
////        btnRecordStop.isUserInteractionEnabled = true
////
////        let scoreResetTap = UITapGestureRecognizer(target: self, action: #selector(scoreLoadButtonTapped(_:)))
////        scoreResetTap.numberOfTapsRequired = 1
////        scoreResetTap.numberOfTouchesRequired = 1
////        btnScoreReset.addGestureRecognizer(scoreResetTap)
////        btnScoreReset.isUserInteractionEnabled = true
//        
//        // set speech model delegate so we can get responses from voice recognition
//        speechModel.delegate = self
//        
//        updateScoreData(shouldAppend: true)
//    }
//    
//    // load navigation bar items
//    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        tabBarController?.navigationItem.title = "Training Sandbox"
//        tabBarController?.navigationItem.rightBarButtonItem = nil
//    }
//    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        // Make sure constraints are finished loading before setting up bubbles
//        chartDidLoad = true
//        viewHasAppeared = true
//        scoresTableView.reloadData()
//    }
//    
//    // MARK: - Button Handling
//    
//    @IBAction func recordButtonTapped(_ sender: Any) {
//        print("~>Record button tapped.")
//        if speechModel.isRecording() {
//            speechModel.stopRecording()
//            animate(button: btnRecordStop, toImage: mic)
//            
//            return
//        }
//        
//        speechModel.checkAuthorization { (authorized) in
//            if authorized && self.speechModel.isAvailable() {
//                self.speechModel.startRecording()
//                self.animate(button: self.btnRecordStop, toImage: self.stop)
//            } else {
//                let alert = UIAlertController(title: "Not Available", message: "Speech recogniztion is not currently available.  Please check your internet connection and try again.", preferredStyle: .alert)
//                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//                self.present(alert, animated: true, completion: nil)
//            }
//        }
//    }
//    
//    // Score or Load New Prompts
//    @IBAction func scoreLoadButtonTapped(_ sender: Any) {
//        
//        // make sure recording has ended first
//        if speechModel.isRecording() {
//            speechModel.stopRecording()
//            animate(button: btnRecordStop, toImage: mic)
//        }
//        
//        if !shouldReset, let text = txtReply.text {
//            if text == "tap microphone to respond to prompt" || text.isEmpty {
//                let alert = UIAlertController(title: "Tap Microphone", message: "You must record a response before you can score it.", preferredStyle: .alert)
//                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//                present(alert, animated: true, completion: nil)
//                return
//            }
//            
//            DispatchQueue.main.async {
//                self.viewModel.calculateScore(fromPhrase: text)
//                self.updateScoreData(shouldAppend: true)
//                self.shouldReset = true
//                self.animate(button: self.btnScoreReset, toImage: self.reset)
//            }
//            
//            
//        } else {
//            
//            DispatchQueue.main.async {
//                self.shouldReset = false
//                self.animate(button: self.btnScoreReset, toImage: self.chart)
//                self.txtReply.text = "tap microphone and start speaking"
//            }
//            
//        }
//        
//    }
//    
//    // MARK: - Score Update Functions
//    
//    private func updateScoreData(shouldAppend append: Bool) {
//        
//        // Get data
//        let lastData = viewModel.getSandboxScore()
//        
//        if append {
//            if let user = FirebaseModel.shared.charmUser, let history = user.trainingData {
//                var sandbox: SandboxTrainingHistory = SandboxTrainingHistory()
//                
//                // append new data to the current user
//                // append process automatically removes anything past 10
//                // and also updates firebase
//                
//                if let sandboxHistory = history.sandboxHistory {
//                    sandbox = sandboxHistory
//                    sandbox.append(lastData)
//                } else {
//                    sandbox.append(lastData)
//                }
//                
//                FirebaseModel.shared.charmUser.trainingData?.sandboxHistory = sandbox
//            }
//        }
//        
//        updateAverageScores()
////        updateLastScores(withData: lastData)
//        scoresTableView.reloadData()
//    }
//    
////    private func updateLastScores(withData data: SandboxScore) {
////        // clear out old data and enter new data
////        lastSliderInfo = []
////        lastSliderInfo.append(SliderCellInfo(details: SliderDetails(type: .fillFromLeft), title: "Length", score: Double(data.length), position: getScorePercent(score: Double(data.length), category: .length)))
////        lastSliderInfo.append(SliderCellInfo(details: SliderDetails(type: .fillFromLeft), title: "Concrete", score: Double(data.concrete), position: getScorePercent(score: Double(data.concrete), category: .concrete)))
////        lastSliderInfo.append(SliderCellInfo(details: SliderDetails(type: .fillFromLeft), title: "Abstract", score: Double(data.abstract), position: getScorePercent(score: Double(data.abstract), category: .abstract)))
////        lastSliderInfo.append(SliderCellInfo(details: SliderDetails(type: .fillFromLeft), title: "Unclassified", score: Double(data.unclassified), position: getScorePercent(score: Double(data.unclassified), category: .length)))
////        lastSliderInfo.append(SliderCellInfo(details: SliderDetails(type: .fillFromLeft), title: "I/Me", score: Double(data.first), position: getScorePercent(score: Double(data.first), category: .first)))
////        lastSliderInfo.append(SliderCellInfo(details: SliderDetails(type: .fillFromLeft), title: "You", score: Double(data.second), position: getScorePercent(score: Double(data.second), category: .second)))
////        lastSliderInfo.append(SliderCellInfo(details: SliderDetails(type: .fillFromLeft), title: "Positive", score: Double(data.length), position: getScorePercent(score: Double(data.positive), category: .positive)))
////        lastSliderInfo.append(SliderCellInfo(details: SliderDetails(type: .fillFromLeft), title: "Negative", score: Double(data.negative), position: getScorePercent(score: Double(data.negative), category: .negative)))
////        lastSliderInfo.append(SliderCellInfo(details: SliderDetails(type: .fillFromLeft), title: "Repeat", score: Double(data.repeated), position: getScorePercent(score: Double(data.repeated), category: .negative)))
////    }
//    
//    private func updateAverageScores() {
//        // clear out the old data and enter new data
//        averageSliderInfo = []
//        let average = viewModel.getSandboxAverage()
//        averageSliderInfo.append(SliderCellInfo(details: SliderDetails(type: .fillFromLeft), title: "Length", score: average.length, position: getScorePercent(score: average.length, category: .length)))
//        averageSliderInfo.append(SliderCellInfo(details: SliderDetails(type: .fillFromLeft), title: "Concrete", score: average.concrete, position: getScorePercent(score: average.concrete, category: .concrete)))
//        averageSliderInfo.append(SliderCellInfo(details: SliderDetails(type: .fillFromLeft), title: "Abstract", score: average.abstract, position: getScorePercent(score: average.abstract, category: .abstract)))
//        averageSliderInfo.append(SliderCellInfo(details: SliderDetails(type: .fillFromLeft), title: "Unclassified", score: average.unclassified, position: getScorePercent(score: average.unclassified, category: .length)))
//        averageSliderInfo.append(SliderCellInfo(details: SliderDetails(type: .fillFromLeft), title: "I/Me", score: average.first, position: getScorePercent(score: average.first, category: .first)))
//        averageSliderInfo.append(SliderCellInfo(details: SliderDetails(type: .fillFromLeft), title: "You", score: average.second, position: getScorePercent(score: average.second, category: .second)))
//        averageSliderInfo.append(SliderCellInfo(details: SliderDetails(type: .fillFromLeft), title: "Positive", score: average.length, position: getScorePercent(score: average.positive, category: .positive)))
//        averageSliderInfo.append(SliderCellInfo(details: SliderDetails(type: .fillFromLeft), title: "Negative", score: average.negative, position: getScorePercent(score: average.negative, category: .negative)))
//        averageSliderInfo.append(SliderCellInfo(details: SliderDetails(type: .fillFromLeft), title: "Repeat", score: average.repeated, position: getScorePercent(score: average.repeated, category: .negative)))
//    }
//    
//    // helper function to calculate position percent
//    private func getScorePercent(score: Double, category: ScorePhraseModel.ChatScoreCategory) -> CGFloat {
//        
//        switch category {
//        case .strength:
//            return CGFloat(score) / 10.0
//        case .length:
//            let percent = CGFloat(score) / 15.0
//            return percent > 1 ? 1 : percent
//        case .positive, .negative:
//            let percent = CGFloat(abs(score)) / 4.0
//            return percent > 1 ? 1 : percent
//        default:
//            let percent = CGFloat(score) / 2.0
//            return percent > 1 ? 1 : percent
//        }
//        
//    }
//    
//    // MARK: - Private Helper Functions
//    
//    // Animation Helpers
//    
//    private func animate(button: UIButton, toImage image: UIImage) {
//        DispatchQueue.main.async {
//            UIView.animate(withDuration: 0.25, animations: {
//                button.alpha = 0
//            }) { (_) in
//                button.setImage(image, for: .normal)
//                UIView.animate(withDuration: 0.25, animations: {
//                    button.alpha = 1.0
//                })
//            }
//        }
//    }
//    
//}
//
//// MARK: - Table View Extension
//
//extension SandboxViewController: UITableViewDelegate, UITableViewDataSource {
//    
//    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        switch section {
//        case 0:
//            return "Length"
//        case 1:
//            return "Concrete"
//        case 2:
//            return "Abstract"
//        case 3:
//            return "Unclassified"
//        case 4:
//            return "I/Me"
//        case 5:
//            return "You"
//        case 6:
//            return "Positive"
//        case 7:
//            return "Negative"
//        case 8:
//            return "Repeat"
//        default:
//            return ""
//        }
//    }
//    
//    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
//        guard let header = view as? UITableViewHeaderFooterView else { return }
//        header.textLabel?.textColor = #colorLiteral(red: 0.1323429346, green: 0.1735357642, blue: 0.2699699998, alpha: 1)
//        header.textLabel?.textAlignment = .natural
//        header.backgroundView?.backgroundColor = .white
//    }
//    
//    func numberOfSections(in tableView: UITableView) -> Int {
//        return 9
//    }
//    
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return 2
//    }
//    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: CellID.scaleBar, for: indexPath) as! ScaleBarTableViewCell
//        guard viewHasAppeared else { return cell }
//        cell.lblDescription.text = indexPath.row == 0 ? "Average" : "Last Phrase"
//        
//        switch indexPath.row {
//        case 0:
//            guard averageSliderInfo.count > indexPath.section else { return cell }
//            let info = averageSliderInfo[indexPath.section]
//            cell.lblScore.text = "\(info.score)"
////            cell.scaleBar.setupBar(ofType: info.type, withValue: info.score, andLabelPosition: info.position)
////            cell.scaleBar.labelType = .RawValue
//            if !cell.sliderView.isSetup {
//                cell.sliderView.setup(for: .fillFromLeft, at: CGFloat(info.position))
//            } else {
//                cell.sliderView.updatePosition(to: CGFloat(info.position))
//            }
//        default:
//            guard lastSliderInfo.count > indexPath.section else { return cell }
//            let info = lastSliderInfo[indexPath.section]
//            cell.lblScore.text = "\(Int(info.score))"
//            
//            if !cell.sliderView.isSetup {
//                cell.sliderView.setup(for: .fillFromLeft, at: CGFloat(info.position))
//            } else {
//                cell.sliderView.updatePosition(to: CGFloat(info.position))
//            }
////            cell.scaleBar.setupBar(ofType: info.type, withValue: info.score, andLabelPosition: info.position)
////            cell.scaleBar.labelType = .IntValue
//        }
//        
//        return cell
//    }
//
//}
//
//// MARK: - Speech Delegate
//
//extension SandboxViewController: SpeechRecognitionDelegate {
//    
//    func speechRecognizerGotText(text: String) {
//        txtReply.text = text
//    }
//    
//}
//
//// MARK: - TextView Delegate
//
//extension SandboxViewController: UITextViewDelegate {
//    
//    func textViewDidBeginEditing(_ textView: UITextView) {
//        if #available(iOS 13.0, *) {
//            textView.textColor = .label
//        } else {
//            textView.textColor = .black
//        }
//        textView.text = textView.text == "tap microphone and start speaking" ? "" : textView.text
//        view.frame.origin.y -= view.frame.height / 3
//    }
//    
//    func textViewDidEndEditing(_ textView: UITextView) {
//        if textView.text.isEmpty || textView.text == "" {
//            textView.textColor = .lightGray
//            textView.text = "tap microphone and start speaking"
//        }
//        
//        view.frame.origin.y = 0
//    }
//    
//    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
//        if text == "\n" {
//            textView.resignFirstResponder()
//            return false
//        } else {
//            return true
//        }
//    }
    
}
