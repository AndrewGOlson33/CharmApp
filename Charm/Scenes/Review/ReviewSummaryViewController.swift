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
    
    // for loading
    @IBOutlet weak var viewLoading: UIView!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    @IBOutlet weak var viewEffect: UIVisualEffectView!
    
    // for chart and table data
    @IBOutlet weak var chartView: HIChartView!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    
    // data chart will be built with
    var snapshot: Snapshot!
    var cellInfo: [SummaryCellInfo] = []
    
    // date formatter for setting chart title
    let dFormatter = DateFormatter()
    
    // Helps deal with layout glitches caused by highcharts
    var chartDidLoad: Bool = false
    
    // MARK: - View Lifecycle Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup notification for new snapshots
        NotificationCenter.default.addObserver(self, selector: #selector(gotNotification(_:)), name: FirebaseNotification.SnapshotLoaded, object: nil)
        
        // round corners of connecting view
        viewLoading.layer.cornerRadius = 20
        viewLoading.layer.shadowColor = UIColor.black.cgColor
        viewLoading.layer.shadowRadius = 8
        viewLoading.layer.shadowOpacity = 0.6
        viewLoading.layer.shadowOffset = CGSize(width: 2, height: 2)
        
        // setup date formatter
        dFormatter.dateStyle = .medium
        
        // Resolve layout issues caused by highcharts
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.chartDidLoad = true
            self.tableView.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.navigationItem.title = "Summary"
        
        setupSnapshotData()
    }
    
    private func setupSnapshotData() {
        guard !SnapshotsLoading.shared.isLoading else {
            if viewLoading.isHidden {
                DispatchQueue.main.async {
                    self.viewLoading.alpha = 0.0
                    self.viewLoading.isHidden = false
                    self.activityView.startAnimating()
                    
                    // disable tab bar buttons
                    if let items = self.tabBarController?.tabBar.items {
                        for item in items {
                            item.isEnabled = false
                        }
                    }
                    
                    UIView.animate(withDuration: 0.25, animations: {
                        self.viewLoading.alpha = 1.0
                    })
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.setupSnapshotData()
                return
            }
            return
        }
        
        if !viewLoading.isHidden {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.25, animations: {
                    self.viewLoading.alpha = 0.0
                }, completion: { (_) in
                    self.activityView.stopAnimating()
                    self.viewLoading.isHidden = true
                    
                    // enable tab bar buttons
                    if let items = self.tabBarController?.tabBar.items {
                        for item in items {
                            item.isEnabled = true
                        }
                    }
                })
            }
        }
        
        // load summary data
        if snapshot == nil {
            guard let data = UserSnapshotData.shared.snapshots.first else {
                
                // setup example
                loadJSONSnapshotData()
                setupSnapshotData()
                
                return
            }
            
            // Set data
            snapshot = data
            UserSnapshotData.shared.selectedSnapshot = snapshot
        } else {
            
            if let first = UserSnapshotData.shared.snapshots.first, let shared = UserSnapshotData.shared.selectedSnapshot, first.date != shared.date {
                UserSnapshotData.shared.selectedSnapshot = first
            } else if let first = UserSnapshotData.shared.snapshots.first, UserSnapshotData.shared.selectedSnapshot == nil {
                UserSnapshotData.shared.selectedSnapshot = first
            }
            
            snapshot = UserSnapshotData.shared.selectedSnapshot
        }
        
        
        // setup chart
        setupSummaryChart()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeSnapshotObserver()
    }
    
    // MARK: - Private Helper Functions
    
    private func loadJSONSnapshotData() {
        viewEffect.isHidden = false
        let noSnapshotsAlert = UIAlertController(title: "No Snapshots Available", message: "Here you can view your converstation metrics.\n\nYour metrics are scored by our servers, and are based on the speaking styles of the world's most charming people.\n\nYou can generate metrics by calling a friend.  It takes our servers about 15 minutes to process your metrics after your call has completed.", preferredStyle: .alert)
        noSnapshotsAlert.addAction(UIAlertAction(title: "View Sample Snapshot", style: .default, handler:{ (_) in
            self.viewEffect.isHidden = true
        }))
        
        present(noSnapshotsAlert, animated: true, completion: nil)
        
        guard let path = Bundle.main.path(forResource: "snapshotData", ofType: "json") else { fatalError("~>Unable to find default JSON file.") }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
            let snapshotData = try JSONDecoder().decode(Snapshot.self, from: data)
            self.snapshot = snapshotData
            UserSnapshotData.shared.selectedSnapshot = snapshot
        } catch let error {
            fatalError("~>Got an error decoding JSON: \(error)")
        }
    }
    
    @objc private func gotNotification(_ sender: Notification) {
        if let items = tabBarController?.tabBar.items {
            for item in items {
                item.isEnabled = true
            }
        }
        
//        viewWillAppear(true)
//        removeSnapshotObserver()
        setupSnapshotData()
    }
    
    fileprivate func removeSnapshotObserver() {
        NotificationCenter.default.removeObserver(self, name: FirebaseNotification.SnapshotLoaded, object: nil)
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
        chartView.plugins = ["variable-pie"]
        chart.type = "variable-pie"
        let title = HITitle()
        
        // Create a legend so we can hide it
        let legend = HILegend()
        legend.enabled = false
        
        // setup pane so polygon is facing up
//        let pane = HIPane()
//        pane.startAngle = 180
//        pane.size = view.frame.width * 0.5
        
        // get date to use for title
        if let date = snapshot.date {
            let dateString = dFormatter.string(from: date)
            title.text = "Your Snapshot from \(dateString)"
        } else {
            title.text = "Your Latest Snapshot"
        }
        
        let tooltip = HITooltip()
        tooltip.headerFormat = ""
        tooltip.pointFormat = "<span style=\"color:{point.color}\">\u{25CF}</span> <b> {point.name}</b><br/>Score: <b>{point.value}</b>"
        
        let yAxis = HIYAxis()
        yAxis.min = 0
        yAxis.lineWidth = 0
        yAxis.gridLineInterpolation = "polygon"
        
//        let xAxis = HIXAxis()
//        xAxis.categories = [
//            "Idea Engagement",
//            "Conversation Engagement",
//            "Personal Connection",
//            "Emotional Connection",
//            "Smiling"
//        ]
//        xAxis.tickmarkPlacement = "on"
//        xAxis.lineWidth = 0
        
        // get and set data
        
        // get values for area chart
//        let concrete = snapshot.getTopLevelScoreValue(forSummaryItem: .Concrete) ?? 0
//        let talking = snapshot.getTopLevelScoreValue(forSummaryItem: .TalkingPercentage) ?? 0
//        let firstPerson = snapshot.getTopLevelScoreValue(forSummaryItem: .FirstPerson) ?? 0
//        let positiveWords = snapshot.getTopLevelScoreValue(forSummaryItem: .PositiveWords) ?? 0
        let smiling = snapshot.getTopLevelScoreValue(forSummaryItem: .SmilingPercentage) ?? 0
        
        // get values for line chart
        let ideaEngagement = snapshot.getTopLevelScoreValue(forSummaryItem: .IdeaEngagement) ?? 0
        let conversationEngagement = snapshot.getTopLevelScoreValue(forSummaryItem: .ConversationEngagement) ?? 0
        let personalConnection = snapshot.getTopLevelScoreValue(forSummaryItem: .PersonalConnection) ?? 0
        let emotionalConnection = snapshot.getTopLevelScoreValue(forSummaryItem: .EmotionalConnection) ?? 0
        
        // get scores for cell info
        let ideaPercent = snapshot.getTopLevelRawValue(forSummaryItem: .IdeaEngagement) ?? 0
        let conversationPercent = snapshot.getTopLevelRawValue(forSummaryItem: .ConversationEngagement) ?? 0
        let personalConnectionPercent = snapshot.getTopLevelRawValue(forSummaryItem: .PersonalConnection) ?? 0
        let emotionalConnectionPercent = snapshot.getTopLevelRawValue(forSummaryItem: .EmotionalConnection) ?? 0
        let smilingPercent = snapshot.getTopLevelRawValue(forSummaryItem: .SmilingPercentage) ?? 0

        // setup cell info array
        cellInfo.append(SummaryCellInfo(title: "Idea Engagement", score: ideaEngagement, percent: ideaPercent))
        cellInfo.append(SummaryCellInfo(title: "Conversation Engagement", score: conversationEngagement, percent: conversationPercent))
        cellInfo.append(SummaryCellInfo(title: "Personal Connection", score: personalConnection, percent: personalConnectionPercent))
        cellInfo.append(SummaryCellInfo(title: "Emotional Connection", score: emotionalConnection, percent: emotionalConnectionPercent))
        cellInfo.append(SummaryCellInfo(title: "Smiling", score: smiling, percent: smilingPercent))

        // setup charts
//        let area = HIArea()
//        area.data = [
//            ["name": "Concrete", "y": concrete],
//            ["name": "Talking %", "y": talking],
//            ["name": "First Person", "y": firstPerson],
//            ["name": "Positive Words", "y": positiveWords],
//            ["name": "Smiling %", "y": smiling]
//        ]
//        area.pointPlacement = "on"
//
//        let line = HILine()
//        line.data = [
//            ["name": "Idea Engagement", "y": ideaEngagement],
//            ["name": "Conversation Engagement", "y": conversationEngagement],
//            ["name": "Personal Connection", "y": personalConnection],
//            ["name": "Emotional Connection", "y": emotionalConnection],
//            ["name": "Smiling %", "y": smiling]
//        ]
        
        let plotoptions = HIPlotOptions()
        
        
        let pie = HIVariablepie()
        pie.dataLabels = []
        let width: Double = 7
        
        pie.minPointSize = 10
        pie.innerSize = "20%"
        pie.zMin = 0
//        pie.zMax = 9
        pie.name = "Snapshot Summary"

        pie.data = [
//            ["name": "Concrete", "y": width, "z": concrete.value(), "value": concrete],
//            ["name": "Talking %", "y": width, "z": talking.value(), "value": talking],
//            ["name": "First Person", "y": width, "z": firstPerson.value(), "value": firstPerson],
//            ["name": "Positive Words", "y": width, "z": positiveWords.value(), "value": positiveWords],
            ["name": "Idea Engagement", "y": width, "z": ideaEngagement.value(), "value": ideaEngagement],
            ["name": "Conversation Engagement", "y": width, "z": conversationEngagement.value(), "value": conversationEngagement],
            ["name": "Personal Connection", "y": width, "z": personalConnection.value(), "value": personalConnection],
            ["name": "Emotional Connection", "y": width, "z": emotionalConnection.value(), "value": emotionalConnection],
            ["name": "Smiling %", "y": width, "z": smiling.value(), "value": smiling],
        ]
        
//        plotoptions.pie = HIPie()
//        let dataLabel = HIDataLabelsOptionsObject()
//        dataLabel.enabled = false
//        plotoptions.pie.dataLabels = [dataLabel]
//
//        let variablePie = HIVariablepie()
//        variablePie.minPointSize = 10
//        variablePie.innerSize = "20%"
//        variablePie.zMin = 0
//        variablePie.name = "Snapshot Summary"
//        variablePie.dataLabels = []
//        variablePie.data = [
//            ["name": "Concrete", "y": concrete],
//            ["name": "Talking %", "y": talking],
//            ["name": "First Person", "y": firstPerson],
//            ["name": "Positive Words", "y": positiveWords],
//            ["name": "Idea Engagement", "y": ideaEngagement],
//            ["name": "Conversation Engagement", "y": conversationEngagement],
//            ["name": "Personal Connection", "y": personalConnection],
//            ["name": "Emotional Connection", "y": emotionalConnection],
//            ["name": "Smiling %", "y": smiling],
//        ]
        
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
//        options.pane = pane
        options.yAxis = [yAxis]
//        options.xAxis = [xAxis]
        options.plotOptions = plotoptions
        options.series = NSMutableArray(objects: pie) as? [HISeries]
        chartView.options = options
    
        // load data into tableview
        tableView.reloadData()
    }
}

extension ReviewSummaryViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SnapshotsLoading.shared.isLoading ? 0 : cellInfo.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard indexPath.row != cellInfo.count else {
            return tableView.dequeueReusableCell(withIdentifier: CellID.ViewPrevious, for: indexPath)
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: CellID.SummaryMetric, for: indexPath) as! SummaryMetricTableViewCell
        let info = cellInfo[indexPath.row]
        cell.lblMetricTitle.text = info.summaryTitle
        cell.lblMetricScore.text = info.detailedScore
        if !cell.sliderView.isSetup {
            cell.sliderView.setup(for: .fillFromLeft, at: CGFloat(info.percent))
        }
        return cell
    }
    
    // MARK: - Popover Setup Helper Functions

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(origin: .zero, size: CGSize(width: tableView.frame.width, height: 1)))
        view.backgroundColor = .clear
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
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

// MARK: - Extension to double to enable squaring

extension Double {
    
    func value() -> Double {
        return pow(2.71828, self)
    }
    
}
