//
//  ReviewSummaryViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 3/18/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit
import Highcharts

class ReviewSummaryViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var chartView: HIChartView!
    
    // score outlets
    @IBOutlet weak var lblWordChoiceScore: UILabel!
    @IBOutlet weak var lblBackAndForthScore: UILabel!
    @IBOutlet weak var lblConnectionScore: UILabel!
    @IBOutlet weak var lblToneOfWordsScore: UILabel!
    
    
    // MARK: - Properties
    
    // data chart will be built with
    var snapshot: Snapshot!
    
    // date formatter for setting chart title
    let dFormatter = DateFormatter()
    
    // MARK: - View Lifecycle Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup date formatter
        dFormatter.dateStyle = .medium
        
        // load summary data
        guard let data = UserSnapshotData.shared.snapshots.first else {
            // TODO: - handle no data
            return
        }
        
        snapshot = data
        
        // setup chart
        setupSummaryChart()
    }
    

    fileprivate func setupSummaryChart() {
        // make sure there is data from summary
        guard snapshot != nil else {
            // TODO: - handle no data
            return
        }
        
        // Setup Chart
        chartView.plugins = ["variable-pie"]
        let options = HIOptions()
        let chart = HIChart()
        chart.type = "variablepie"
        let title = HITitle()
        
        // get date to use for title
        if let date = snapshot.date {
            let dateString = dFormatter.string(from: date)
            title.text = "Your Snapshot from \(dateString)"
        } else {
            title.text = "Your Latest Snapshot"
        }
        
        let tooltip = HITooltip()
        tooltip.headerFormat = ""
        tooltip.pointFormat = "<span style=\"color:{point.color}\">\u{25CF}</span> <b> {point.name}</b><br/>Score: <b>{point.y}</b>"
        
        let variablepie = HIVariablepie()
        variablepie.minPointSize = NSNumber(value: 1)
        variablepie.innerSize = "20%"
        variablepie.zMin = NSNumber(value: 0)
//        variablepie.name = "Summary"
        variablepie.dataLabels = HIDataLabels()
        variablepie.dataLabels.enabled = NSNumber(value: false)
        
        // get and set data
        let wordChoiceRaw = snapshot.getTopLevelRawValue(forSummaryItem: .WordChoice) ?? 0
        let backAndForthRaw = snapshot.getTopLevelRawValue(forSummaryItem: .BackAndForth) ?? 0
        let connectionRaw = snapshot.getTopLevelRawValue(forSummaryItem: .Connection) ?? 0
        let toneRaw = snapshot.getTopLevelRawValue(forSummaryItem: .ToneOfWords) ?? 0
        
        let total = wordChoiceRaw + backAndForthRaw + connectionRaw + toneRaw
        
        // set lables
        lblWordChoiceScore.text = "\(wordChoiceRaw)"
        lblBackAndForthScore.text = "\(backAndForthRaw)"
        lblConnectionScore.text = "\(connectionRaw)"
        lblToneOfWordsScore.text = "\(toneRaw)"
        
        // set chart data
        variablepie.data = [
            ["name": "Word Choice", "y": wordChoiceRaw, "z" : wordChoiceRaw / total],
            ["name": "Back and Forth", "y": backAndForthRaw, "z" : backAndForthRaw / total],
            ["name": "Connection", "y": connectionRaw, "z" : connectionRaw / total],
            ["name": "Tone of Words", "y": toneRaw, "z" : toneRaw / total]
        ]
        
        // load options and show chart
        options.chart = chart
        options.title = title
        options.tooltip = tooltip
        options.series = [variablepie]
        chartView.options = options
    }
}
