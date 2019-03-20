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
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var viewNoSnapshots: UIView!
    
    // MARK: - Properties
    
    // data chart will be built with
    var snapshot: Snapshot!
    var cellInfo: [SummaryCellInfo] = []
    
    // date formatter for setting chart title
    let dFormatter = DateFormatter()
    
    // MARK: - View Lifecycle Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup date formatter
        dFormatter.dateStyle = .medium
        
        // load summary data
        guard let data = UserSnapshotData.shared.snapshots.first else {
            viewNoSnapshots.alpha = 0.0
            viewNoSnapshots.isHidden = false
            UIView.animate(withDuration: 0.25) {
                self.viewNoSnapshots.alpha = 1.0
            }
            
            // disable tab bar buttons
            if let items = tabBarController?.tabBar.items {
                for item in items {
                    item.isEnabled = false
                }
            }
            
            return
        }
        
        // Set data
        snapshot = data
        UserSnapshotData.shared.selectedSnapshot = snapshot
        
        // setup chart
        setupSummaryChart()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.navigationItem.title = "Summary"
    }
    

    fileprivate func setupSummaryChart() {
        // make sure there is data from summary
        guard snapshot != nil else {
            // No data case is handled in load methods (will show a screen overlay with label saying there are no snapshots)
            return
        }
        
        // Setup Chart
        let options = HIOptions()
        let chart = HIChart()
        chart.polar = true
        chart.type = "line"
        let title = HITitle()
        
        // Create a legend so we can hide it
        let legend = HILegend()
        legend.enabled = false
        
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
        
        let yAxis = HIYAxis()
        yAxis.min = 0
        yAxis.lineWidth = 0
        yAxis.gridLineInterpolation = "polygon"
        
        let xAxis = HIXAxis()
        xAxis.categories = [
            "Word Choice",
            "Back and Forth",
            "Connection",
            "Tone of Words"
        ]
        xAxis.tickmarkPlacement = "on"
        xAxis.lineWidth = 0
        
        // get and set data
        let wordChoiceRaw = snapshot.getTopLevelRawValue(forSummaryItem: .WordChoice) ?? 0
        let backAndForthRaw = snapshot.getTopLevelRawValue(forSummaryItem: .BackAndForth) ?? 0
        let connectionRaw = snapshot.getTopLevelRawValue(forSummaryItem: .Connection) ?? 0
        let toneRaw = snapshot.getTopLevelRawValue(forSummaryItem: .ToneOfWords) ?? 0
        
        cellInfo.append(SummaryCellInfo(title: "Word Choice", score: wordChoiceRaw))
        cellInfo.append(SummaryCellInfo(title: "Back and Forth", score: backAndForthRaw))
        cellInfo.append(SummaryCellInfo(title: "Connection", score: connectionRaw))
        cellInfo.append(SummaryCellInfo(title: "Tone of Words", score: toneRaw))
        
        let area = HIArea()
        area.data = [
            ["name": "Word Choice", "y": wordChoiceRaw],
            ["name": "Back and Forth", "y": backAndForthRaw],
            ["name": "Connection", "y": connectionRaw],
            ["name": "Tone of Words", "y": toneRaw]
        ]
        area.pointPlacement = "on"
        
        // hide hamburger button
        let navigation = HINavigation()
        let buttonOptions = HIButtonOptions()
        buttonOptions.enabled = false
        navigation.buttonOptions = buttonOptions
        options.navigation = navigation
        
        // load options and show chart
        options.chart = chart
        options.title = title
        options.tooltip = tooltip
        options.legend = legend
        options.yAxis = [yAxis]
        options.xAxis = [xAxis]
        options.series = [area]
        chartView.options = options
        
        // load data into tableview
        tableView.reloadData()
    }
}

extension ReviewSummaryViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellInfo.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard viewNoSnapshots.isHidden else {
            // just return an empty cell
            return UITableViewCell()
        }
        
        guard indexPath.row != cellInfo.count else {
            return tableView.dequeueReusableCell(withIdentifier: CellID.ViewPrevious, for: indexPath)
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: CellID.SummaryMetric, for: indexPath) as! SummaryMetricTableViewCell
        let info = cellInfo[indexPath.row]
        cell.lblMetric.text = info.title
        cell.lblScore.text = info.scoreString
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(origin: .zero, size: CGSize(width: tableView.frame.width, height: 1)))
        view.backgroundColor = .clear
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellInfo.count == indexPath.row ? 44 : 50
    }
    
    // MARK: - Handle TableView Actions
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row < 4 {
            tabBarController?.selectedIndex = indexPath.row + 1
        }
    }
    
}
