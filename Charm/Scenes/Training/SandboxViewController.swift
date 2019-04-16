//
//  SandboxViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 3/25/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit
import Highcharts
import Speech

class SandboxViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var chartView: HIChartView!
    @IBOutlet weak var txtReply: UITextView!
    @IBOutlet weak var btnRecordStop: UIImageView!
    @IBOutlet weak var btnScoreReset: UIImageView!
    
    // MARK: - Properties
    
    // View Model
    let viewModel = ScorePhraseModel()
    var speechModel: SpeechRecognitionModel = SpeechRecognitionModel()
    
    // Detect if we are in score or reset mode
    private var shouldReset = false
    
    // Button Images
    
    let mic = UIImage(named: Image.Mic)!
    let stop = UIImage(named: Image.Stop)!
    let chart = UIImage(named: Image.Update)!
    let reset = UIImage(named: Image.Reset)!
    
    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // setup text view
        txtReply.delegate = self
        txtReply.textColor = .lightGray
        txtReply.text = "tap microphone and start speaking"
        
        // Setup Button Taps
        
        let recordStopTap = UITapGestureRecognizer(target: self, action: #selector(recordButtonTapped(_:)))
        recordStopTap.numberOfTapsRequired = 1
        recordStopTap.numberOfTouchesRequired = 1
        btnRecordStop.addGestureRecognizer(recordStopTap)
        btnRecordStop.isUserInteractionEnabled = true
        
        let scoreResetTap = UITapGestureRecognizer(target: self, action: #selector(scoreLoadButtonTapped(_:)))
        scoreResetTap.numberOfTapsRequired = 1
        scoreResetTap.numberOfTouchesRequired = 1
        btnScoreReset.addGestureRecognizer(scoreResetTap)
        btnScoreReset.isUserInteractionEnabled = true
        
        // set speech model delegate so we can get responses from voice recognition
        speechModel.delegate = self
        
        setupChart()
        
        DispatchQueue.main.async {
            self.updateChartData(shouldAppend: false)
        }

    }
    
    // load navigation bar items
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.navigationItem.title = "Training Sandbox"
        let info = UIBarButtonItem(image: UIImage(named: Image.Info), style: .plain, target: self, action: #selector(infoButtonTapped))
        tabBarController?.navigationItem.rightBarButtonItem = info
    }
    
    // MARK: - Button Handling
    
    @IBAction func recordButtonTapped(_ sender: Any) {
        print("~>Record button tapped.")
        if speechModel.isRecording() {
            speechModel.stopRecording()
            animate(button: btnRecordStop, toImage: mic)
            
            return
        }
        
        speechModel.checkAuthorization { (authorized) in
            if authorized && self.speechModel.isAvailable() {
                self.speechModel.startRecording()
                self.animate(button: self.btnRecordStop, toImage: self.stop)
            } else {
                let alert = UIAlertController(title: "Not Available", message: "Speech recogniztion is not currently available.  Please check your internet connection and try again.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    // Score or Load New Prompts
    @IBAction func scoreLoadButtonTapped(_ sender: Any) {
        
        // make sure recording has ended first
        if speechModel.isRecording() {
            speechModel.stopRecording()
            animate(button: btnRecordStop, toImage: mic)
        }
        
        if !shouldReset, let text = txtReply.text {
            if text == "tap microphone to respond to prompt" || text.isEmpty {
                let alert = UIAlertController(title: "Tap Microphone", message: "You must record a response before you can score it.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                present(alert, animated: true, completion: nil)
                return
            }
            
            DispatchQueue.main.async {
                self.viewModel.calculateScore(fromPhrase: text)
                self.updateChartData(shouldAppend: true)
                self.shouldReset = true
                self.animate(button: self.btnScoreReset, toImage: self.reset)
            }
            
            
        } else {
            
            DispatchQueue.main.async {
                self.shouldReset = false
                self.animate(button: self.btnScoreReset, toImage: self.chart)
                self.txtReply.text = "tap microphone and start speaking"
            }
            
        }
        
    }
    
    // MARK: - Chart Setup
    
    private func setupChart() {
        let chart = HIChart()
        chart.type = "bar"
        
        let title = HITitle()
        title.text = "Instant Training"
        
        let xaxis = HIXAxis()
        xaxis.categories = [
            "Length",
            "Concrete",
            "Abstract",
            "Unclassified",
            "I/Me",
            "You",
            "Positive",
            "Negative",
            "Repeat"
        ]
        
        let yaxis = HIYAxis()
        yaxis.title = HITitle()
        yaxis.title.text = ""
        yaxis.min = 0
        
        let tooltip = HITooltip()
//        tooltip.valuePrefix = "Value: "
        
        let plotOptions = HIPlotOptions()
        plotOptions.bar = HIBar()
        plotOptions.bar.dataLabels = HIDataLabelsOptionsObject()
        plotOptions.bar.dataLabels.enabled = true
        
        let legend = HILegend()
        legend.layout = "proximate"
        legend.align = "right"
//        legend.verticalAlign = "bottom"
//        legend.x = -20
        legend.y = -20
        legend.floating = true
        legend.borderWidth = 1
        legend.backgroundColor = HIColor(uiColor: .white)
        legend.shadow = true
        
        // hide hamburger button
        let navigation = HINavigation()
        let buttonOptions = HIButtonOptions()
        buttonOptions.enabled = false
        navigation.buttonOptions = buttonOptions
        
        let averageBar = HIBar()
        let lastBar = HIBar()
        
        let blankData = [0, 0, 0, 0, 0, 0, 0, 0, 0]
        averageBar.name = "Average"
        lastBar.name = "Last Phrase"
        
        let average = viewModel.getSandboxAverage()
        averageBar.data = [average.length, average.concrete, average.abstract, average.unclassified, average.first, average.second, average.positive, average.negative, average.repeated]
        lastBar.data = blankData
        
        let options = HIOptions()
        options.chart = chart
        options.title = title
        options.xAxis = [xaxis]
        options.yAxis = [yaxis]
        options.tooltip = tooltip
        options.plotOptions = plotOptions
        options.legend = legend
        options.series = [averageBar, lastBar]
        options.navigation = navigation
        
        chartView.options = options
        
    }
    
    private func updateChartData(shouldAppend append: Bool) {
        let averageBar = HIBar()
        let lastBar = HIBar()
        
        averageBar.name = "Average"
        lastBar.name = "Last Phrase"
    
        // Get data
        let lastData = viewModel.getSandboxScore()
        
        if append {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            if let user = appDelegate.user, let history = user.trainingData {
                var sandbox: SandboxTrainingHistory = SandboxTrainingHistory()
                
                // append new data to the current user
                // append process automatically removes anything past 10
                // and also updates firebase
                
                if let sandboxHistory = history.sandboxHistory {
                    sandbox = sandboxHistory
                    sandbox.append(lastData)
                } else {
                    sandbox.append(lastData)
                }
                
                appDelegate.user.trainingData?.sandboxHistory = sandbox
            }
        }
        
        let averageData = viewModel.getSandboxAverage()
        print("~>Average data is: \(averageData)")
        
        averageBar.data = [averageData.length, averageData.concrete, averageData.abstract, averageData.unclassified, averageData.first, averageData.second, averageData.positive, averageData.negative, averageData.repeated]
        lastBar.data = [lastData.length, lastData.concrete, lastData.abstract, lastData.unclassified, lastData.first, lastData.second, lastData.positive, lastData.negative, lastData.repeated]
        
        chartView.options.series = [averageBar, lastBar]
        
    }
    
    // MARK: - Private Helper Functions
    
    @objc private func infoButtonTapped() {
        print("~>Info button tapped.")
    }
    
    // Animation Helpers
    
    private func animate(button: UIImageView, toImage image: UIImage) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.25, animations: {
                button.alpha = 0
            }) { (_) in
                button.image = image
                UIView.animate(withDuration: 0.25, animations: {
                    button.alpha = 1.0
                })
            }
        }
    }
    
}

// MARK: - Speech Delegate

extension SandboxViewController: SpeechRecognitionDelegate {
    
    func speechRecognizerGotText(text: String) {
        txtReply.text = text
    }
    
}

// MARK: - TextView Delegate

extension SandboxViewController: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.textColor = .black
        textView.text = textView.text == "tap microphone and start speaking" ? "" : textView.text
        view.frame.origin.y -= view.frame.height / 3
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty || textView.text == "" {
            textView.textColor = .lightGray
            textView.text = "tap microphone and start speaking"
        }
        
        view.frame.origin.y = 0
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        } else {
            return true
        }
    }
    
}
