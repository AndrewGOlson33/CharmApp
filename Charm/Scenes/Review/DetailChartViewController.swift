//
//  DetailChartViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 3/19/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit
import Highcharts

class DetailChartViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var chartView: HIChartView!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    
    // data chart will be built with
    var snapshot: Snapshot!
    var transcript: [TranscriptCellInfo] = []
    var scalebarData: [ScalebarCellInfo] = []
    
    // date formatter for setting chart title
    let dFormatter = DateFormatter()
    
    // chart type (used to figure out which data to present)
    var chartType: ChartType!
    
    // data used for creating chart
    var chartData: [Any] = []
    
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadData()
        setupChart()
    }
    
    private func loadData() {
        // clear any old values
        chartData = []
        scalebarData = []
        transcript = []
        
        // setup data based on type
        switch chartType! {
        case .BackAndForth:
            let backAndForth = snapshot.backAndForth
            // setup chart data
            for (index, item) in backAndForth.enumerated() {
                if let value = item.adjustedAvg {
                    chartData.append([index, value])
                }
            }
            
            // setup scale bar data
            if let engagementRaw = snapshot.getTopLevelRawValue(forSummaryItem: .BackAndForth), let engagementLevel = snapshot.getTopLevelRawLevelValue(forSummaryItem: .BackAndForth) {
                let cellInfo = ScalebarCellInfo(type: .Green, title: "Estimated Engagement", score: engagementRaw, position: engagementLevel)
                scalebarData.append(cellInfo)
            }
            
            if let talkingRaw = snapshot.getTopLevelRawValue(forSummaryItem: .Talking), let talkingLevel = snapshot.getTopLevelRawLevelValue(forSummaryItem: .Talking) {
                let cellInfo = ScalebarCellInfo(type: .BlueCenter, title: "Talking Percentage", score: talkingRaw, position: talkingLevel)
                scalebarData.append(cellInfo)
            }
            
            // setup transcript
            for item in snapshot.transcript {
                let text = "[\(item.person)]: \(item.words)"
                transcript.append(TranscriptCellInfo(withText: text))
            }
            
        case .Connection:
            let connection = snapshot.connection
            // setup chart data
            for (index, item) in connection.enumerated() {
                // add transcript data
                let pronoun = Pronoun.init(rawValue: item.pronoun) ?? .FirstPerson
                let text = "[\(index)]: \(item.word) (\(pronoun.description))"
                transcript.append(TranscriptCellInfo(withText: text))
                
                // add chart data
                if let value = item.adjustedAverage {
                    chartData.append([index, value])
                }
            }
            
            // setup scale bar data
            if let connectionRaw = snapshot.getTopLevelRawValue(forSummaryItem: .Connection), let connectionLevel = snapshot.getTopLevelRawLevelValue(forSummaryItem: .Connection) {
                let cellInfo = ScalebarCellInfo(type: .Green, title: "Estimated Connection", score: connectionRaw, position: connectionLevel)
                scalebarData.append(cellInfo)
            }
            
            if let firstPersonRaw = snapshot.getTopLevelRawValue(forSummaryItem: .ConnectionFirstPerson), let firstPersonLevel = snapshot.getTopLevelRawLevelValue(forSummaryItem: .ConnectionFirstPerson) {
                let cellInfo = ScalebarCellInfo(type: .BlueCenter, title: "First Person Percentage", score: firstPersonRaw, position: firstPersonLevel)
                scalebarData.append(cellInfo)
            }
        
        }
        
        tableView.reloadData()
    }
    
    private func setupChart() {
        
        // make sure there is data from summary
        guard snapshot != nil else {
            // TODO: - handle no data
            return
        }
        
        // Setup Chart
        
        // chart colors
        let colorArray = [
            [NSNumber(value: 0), "rgb(0, 128 ,0)"],
            [NSNumber(value: 0.5), "rgba(216,216,216, 0)"],
            [NSNumber(value: 0.7), "rgba(47,216,216,0)"],
            [NSNumber(value: 1), "rgb(255, 0 ,0)"]]
        
        let options = HIOptions()
        let title = HITitle()
        
        // get date to use for title
        if let date = snapshot.date {
            let dateString = dFormatter.string(from: date)
            title.text = "Your Snapshot from \(dateString)"
        } else {
            title.text = "Your Latest Snapshot"
        }
        
        let subtitle = HISubtitle()
        subtitle.text = "Click and drag in the plot area to zoom in"
        
        let chart = HIChart()
        chart.zoomType = "x"
        
        let yaxis = HIYAxis()
        yaxis.title = HITitle()
        yaxis.title.text = "Word Score"
        yaxis.visible = true
        
        let xaxis = HIXAxis()
        xaxis.title = HITitle()
        xaxis.title.text = "Word in Conversation"
        xaxis.visible = true
        
        let legend = HILegend()
        legend.enabled = false
        
        let plotoptions = HIPlotOptions()
        plotoptions.area = HIArea()
        plotoptions.area.fillColor = HIColor(linearGradient: [
            "x1": NSNumber(value: 0),
            "x2": NSNumber(value: 0),
            "y1": NSNumber(value: 0),
            "y2": NSNumber(value: 1)
            ], stops: colorArray)
        plotoptions.area.marker = HIMarker()
        plotoptions.area.marker.radius = NSNumber(value: 2)
        plotoptions.area.lineWidth = 1
        let state = HIStates()
        state.hover = HIHover()
        state.hover.lineWidth = 1
        plotoptions.area.states = state
        
        let area = HIArea()
        area.name = chartType.rawValue
        area.data = chartData
        
        options.chart = chart
        options.title = title
        options.subtitle = subtitle
        options.legend = legend
        options.yAxis = [yaxis]
        options.xAxis = [xaxis]
        options.plotOptions = plotoptions
        options.series = [area]
        
        // hide hamburger button
        let navigation = HINavigation()
        let buttonOptions = HIButtonOptions()
        buttonOptions.enabled = false
        navigation.buttonOptions = buttonOptions
        options.navigation = navigation
        
        chartView.options = options
        tableView.reloadData()
    }

}

extension DetailChartViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return scalebarData.count
        default:
            return transcript.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0:
            // setup scalebar
            let cell = tableView.dequeueReusableCell(withIdentifier: CellID.ScaleBar, for: indexPath) as! ScaleBarTableViewCell
            let info = scalebarData[indexPath.row]
            cell.scaleBar.setupBar(ofType: info.type, withValue: info.score, andLabelPosition: info.position)
            cell.lblDescription.text = info.title
            return cell
        default:
            // setup transcript
            let cell = tableView.dequeueReusableCell(withIdentifier: CellID.Transcript, for: indexPath) as! TranscriptTableViewCell
            let info = transcript[indexPath.row]
            cell.lblTranscriptText.text = info.text
            return cell
        }
        
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let cell = tableView.cellForRow(at: indexPath) as? ScaleBarTableViewCell {
            tableView.deselectRow(at: indexPath, animated: false)
            setupPopover(for: cell)
        }
        
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    
    private func getX(for bar: ScaleBar) -> CGFloat {
        let value = CGFloat(bar.calculatedValue)
        return bar.bounds.width * value
    }
    
    private func setupPopover(for cell: ScaleBarTableViewCell) {
        let popoverContent = self.storyboard?.instantiateViewController(withIdentifier: StoryboardID.LabelPopover) as? LabelBubbleViewController
        popoverContent?.modalPresentationStyle = .popover
        popoverContent?.labelText = cell.scaleBar.getStringValue()
        
        if let bubble = popoverContent?.popoverPresentationController {
            bubble.permittedArrowDirections = .down
            bubble.backgroundColor = #colorLiteral(red: 0.7843906283, green: 0.784409225, blue: 0.7843992114, alpha: 1)
            bubble.sourceView = cell
            bubble.sourceRect = CGRect(x: getX(for: cell.scaleBar), y: cell.scaleBar.frame.minY - 2, width: 0, height: 0)
            bubble.delegate = self
            if let popoverController = popoverContent {
                present(popoverController, animated: true, completion: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                        popoverController.dismiss(animated: true, completion: nil)
                    })
                })
            }
        }
    }

}

// MARK: - Extension to enable popover presentation

extension DetailChartViewController: UIPopoverPresentationControllerDelegate {
    //UIPopoverPresentationControllerDelegate inherits from UIAdaptivePresentationControllerDelegate, we will use this method to define the presentation style for popover presentation controller
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    //UIPopoverPresentationControllerDelegate
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        
    }
    
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        return true
    }
}
