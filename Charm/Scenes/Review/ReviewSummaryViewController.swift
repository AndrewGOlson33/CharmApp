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
        
        // Start pulling training data
        let _ = TrainingModelCapsule.shared.model.abstractNouns
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.navigationItem.title = "Summary"
        
        // load summary data
        if snapshot == nil {
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
        } else {
            snapshot = UserSnapshotData.shared.selectedSnapshot
        }
        
        
        // setup chart
        setupSummaryChart()
    }
    

    fileprivate func setupSummaryChart() {
        // make sure there is data from summary
        guard snapshot != nil else {
            // No data case is handled in load methods (will show a screen overlay with label saying there are no snapshots)
            return
        }
        
        // clear out cell info array so we don't add a ton of unwanted cell
        cellInfo = []
        
        // Setup Chart
        let options = HIOptions()
        let chart = HIChart()
        chart.polar = true
        chart.type = "line"
        let title = HITitle()
        
        // Create a legend so we can hide it
        let legend = HILegend()
        legend.enabled = false
        
        // setup pane so polygon is facing up
        let pane = HIPane()
        pane.startAngle = 180
        
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
            "Concrete Details",
            "Back and Forth",
            "Connection",
            "Positivity",
            "Smiling"
        ]
        xAxis.tickmarkPlacement = "on"
        xAxis.lineWidth = 0
        
        // get and set data
        
        // ctn / eng score values
        let concreteDetailsEngScore = snapshot.getTopLevelScoreValue(forSummaryItem: .WordChoice) ?? 0
        let backAndForthEngScore = snapshot.getTopLevelScoreValue(forSummaryItem: .BackAndForth) ?? 0
        let connectionCtnScore = snapshot.getTopLevelScoreValue(forSummaryItem: .Connection) ?? 0
        let toneCtnScore = snapshot.getTopLevelScoreValue(forSummaryItem: .ToneOfWords) ?? 0
        
        // raw score values
        let concreteDetailsRawScore = snapshot.getTopLevelScoreValue(forSummaryItem: .ConcretePercentage) ?? 0
        let backAndForthRawScore = snapshot.getTopLevelScoreValue(forSummaryItem: .Talking) ?? 0
        let connectionRawScore = snapshot.getTopLevelScoreValue(forSummaryItem: .ConnectionFirstPerson) ?? 0
        let toneRawScore = snapshot.getTopLevelScoreValue(forSummaryItem: .PositiveWords) ?? 0
        
        // ctn / eng raw values
        let concreteDetailsEngRaw = snapshot.getTopLevelRawValue(forSummaryItem: .WordChoice) ?? 0
        let backAndForthEngRaw = snapshot.getTopLevelRawValue(forSummaryItem: .BackAndForth) ?? 0
        let connectionCtnRaw = snapshot.getTopLevelRawValue(forSummaryItem: .Connection) ?? 0
        let toneCtnRaw = snapshot.getTopLevelRawValue(forSummaryItem: .ToneOfWords) ?? 0
        
        // raw raw values
        let concreteDetailsEngRawRaw = snapshot.getTopLevelRawLevelValue(forSummaryItem: .WordChoice) ?? 0
        let backAndForthEngRawRaw = snapshot.getTopLevelRawLevelValue(forSummaryItem: .BackAndForth) ?? 0
        let connectionCtnRawRaw = snapshot.getTopLevelRawLevelValue(forSummaryItem: .Connection) ?? 0
        let toneCtnRawRaw = snapshot.getTopLevelRawLevelValue(forSummaryItem: .ToneOfWords) ?? 0
        
        
        cellInfo.append(SummaryCellInfo(title: "Concrete Details", score: concreteDetailsEngRaw, percent: concreteDetailsEngRawRaw))
        cellInfo.append(SummaryCellInfo(title: "Back and Forth", score: backAndForthEngRaw, percent: backAndForthEngRawRaw))
        cellInfo.append(SummaryCellInfo(title: "Connection", score: connectionCtnRaw, percent: connectionCtnRawRaw))
        cellInfo.append(SummaryCellInfo(title: "Emotions", score: toneCtnRaw, percent: toneCtnRawRaw))
        cellInfo.append(SummaryCellInfo(title: "Smiling", score: toneCtnRaw, percent: toneCtnRawRaw))
        
        let area = HIArea()
        area.data = [
            ["name": "Concrete Details", "y": concreteDetailsEngScore],
            ["name": "Back and Forth", "y": backAndForthEngScore],
            ["name": "Connection", "y": connectionCtnScore],
            ["name": "Positivity", "y": toneCtnScore],
            ["name": "Smiling", "y": toneCtnScore]
        ]
        area.pointPlacement = "on"
        
        let line = HILine()
        line.data = [
            ["name": "Concrete Details", "y": concreteDetailsRawScore],
            ["name": "Back and Forth", "y": backAndForthRawScore],
            ["name": "Connection", "y": connectionRawScore],
            ["name": "Positivity", "y": toneRawScore],
            ["name": "Smiling", "y": toneCtnScore]
        ]
        
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
        options.pane = pane
        options.yAxis = [yAxis]
        options.xAxis = [xAxis]
        options.series = [area, line]
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
        
        var header = ""
        
        switch info.title {
        case "Concrete Details":
            header = "Estimated Engagement:"
            cell.lblScoreDetail.isHidden = true
        case "Back and Forth":
            cell.lblScoreDetail.text = "Talking Time"
            cell.lblScoreDetail.isHidden = false
            header = "Estimated Engagement:"
        case "Connection":
            cell.lblScoreDetail.text = "First Person"
            cell.lblScoreDetail.isHidden = false
            header = "Estimated Connection:"
        case "Positivity":
            cell.lblScoreDetail.isHidden = true
            header = "Estimated Connection:"
        case "Smiling":
            cell.lblScoreDetail.isHidden = true
            header = "Last Snapshot:"
        default:
            cell.lblScoreDetail.isHidden = true
        }
        
        cell.lblMetricDetail.text = "\(header) \(info.scoreString)"
        cell.lblScore.text = info.percentString
        
        
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
        } else if indexPath.row == 5 {
            performSegue(withIdentifier: SegueID.SnapshotsList, sender: self)
        }
    }
    
}
