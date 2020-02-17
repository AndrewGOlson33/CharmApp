//
//  AllSnapshotsSummaryViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 8/19/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit
import Highcharts

struct CategoryArea {
    var name: String
    var scores: [Int]
    
    mutating func add(score: Int) {
        scores.insert(score, at: 0)
    }
    
    mutating func clear() {
        scores = []
    }
}

class AllSnapshotsSummaryViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var chartView: HIChartView!
    
    // MARK: - Properties
    
    // snapshot data
    private var snapshots = FirebaseModel.shared.snapshots
    
    // data from snapshots for chart
    var xAxisCategories: [String] = []
    
    // data
    var ideaData: CategoryArea = CategoryArea(name: "Idea", scores: [])
    var convoData: CategoryArea = CategoryArea(name: "Convo", scores: [])
    var personalData: CategoryArea = CategoryArea(name: "Personal", scores: [])
    var emotionalData: CategoryArea = CategoryArea(name: "Emotional", scores: [])
    var smilingData: CategoryArea = CategoryArea(name: "Smiling", scores: [])
    
    let dFormatter: DateFormatter = DateFormatter()
    
    // MARK: - View Lifecycle Functions

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // configure date formatter
        dFormatter.dateStyle = .short
        dFormatter.timeStyle = .none
        
        clearData()
        loadChartData()
        setupLineChart()
    }
    
    // MARK: - Chart Setup
    
    private func clearData() {
        xAxisCategories = []
        ideaData.clear()
        convoData.clear()
        personalData.clear()
        emotionalData.clear()
        smilingData.clear()
    }
    
    private func loadChartData() {
        
        for snapshot in snapshots {
            // we only should be loading snapshots with valid dates (all should be valid)
            if let date = snapshot.date {
                xAxisCategories.insert(dFormatter.string(from: date), at: 0)
                ideaData.add(score: Int(snapshot.getTopLevelScoreValue(forSummaryItem: .ideaEngagement) ?? 0))
                convoData.add(score: Int(snapshot.getTopLevelScoreValue(forSummaryItem: .conversationEngagement) ?? 0))
                personalData.add(score: Int(snapshot.getTopLevelScoreValue(forSummaryItem: .personalConnection) ?? 0))
                emotionalData.add(score: Int(snapshot.getTopLevelScoreValue(forSummaryItem: .emotionalConnection) ?? 0))
                smilingData.add(score: Int(snapshot.getTopLevelScoreValue(forSummaryItem: .smilingPercentage) ?? 0))
            }
        }
    }
    
    private func setupLineChart() {
        let options = HIOptions()
        let chart = HIChart()
        chart.type = "area"
        chart.spacing = [0, 0, 0, 0]
        chart.backgroundColor = HIColor(uiColor: .clear)
        
        // set a blank title
        let title = HITitle()
        title.text = ""
        
        // x axis setup
        let xAxis = HIXAxis()
        xAxis.categories = xAxisCategories
        xAxis.tickmarkPlacement = "on"
        xAxis.title = HITitle()
        xAxis.title.text = ""
        
        // y axis setup
        let yAxis = HIYAxis()
        yAxis.title = HITitle()
        yAxis.title.text = ""
        yAxis.labels = HILabels()
        yAxis.labels.enabled = false
        
        let plotOptions = HIPlotOptions()
        plotOptions.area = HIArea()
        plotOptions.area.stacking = "normal"
        plotOptions.area.lineColor = HIColor(uiColor: #colorLiteral(red: 0.4756349325, green: 0.4756467342, blue: 0.4756404161, alpha: 1))
        plotOptions.area.lineWidth = 1
        
        plotOptions.area.marker = HIMarker()
        plotOptions.area.marker.lineWidth = 1
        plotOptions.area.marker.lineColor = "#797979"
        
        // hide hamburger button
        let navigation = HINavigation()
        let buttonOptions = HIButtonOptions()
        buttonOptions.enabled = false
        navigation.buttonOptions = buttonOptions
        options.navigation = navigation
        
        let ideaArea = HIArea()
        let convoArea = HIArea()
        let personalArea = HIArea()
        let emotionalArea = HIArea()
        let smilingArea = HIArea()
        
        ideaArea.name = ideaData.name
        convoArea.name = convoData.name
        personalArea.name = personalData.name
        emotionalArea.name = emotionalData.name
        smilingArea.name = smilingData.name
        
        ideaArea.data = ideaData.scores
        convoArea.data = convoData.scores
        personalArea.data = personalData.scores
        emotionalArea.data = emotionalData.scores
        smilingArea.data = smilingData.scores
        
        options.chart = chart
        options.title = title
        options.xAxis = [xAxis]
        options.yAxis = [yAxis]
        options.plotOptions = plotOptions
        options.series = [ideaArea, convoArea, personalArea, emotionalArea, smilingArea]
        
        // remove chart credits
        options.credits = HICredits()
        options.credits.enabled = false
        
        chartView.options = options
    }
}

// MARK: - Table View Extension

extension AllSnapshotsSummaryViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return snapshots.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellID.snapshotList, for: indexPath) as! SnapshotSummaryTableViewCell
        
        cell.snapshot = snapshots[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let snapshot = snapshots[indexPath.row]
        
        FirebaseModel.shared.selectedSnapshot = snapshot
        navigationController?.popViewController(animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 160
    }
}
