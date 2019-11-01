//
//  SnapshotSummaryTableViewCell.swift
//  Charm
//
//  Created by Daniel Pratt on 8/19/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit
import Highcharts

class SnapshotSummaryTableViewCell: UITableViewCell {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var lblSummaryTitle: UILabel!
    @IBOutlet weak var mindChart: HIChartView!
    @IBOutlet weak var heartChart: HIChartView!
    
    var snapshot: Snapshot! {
        didSet {
            loadData()
        }
    }
    
    // Data to display
    private var title: String = ""
    private var friendName: String = "Unknown User"
    private var date: Date? = nil
    
    private var scoreIdea: Double = 0 {
        didSet {
            scoreIdea = round(scoreIdea * 10) / 10
        }
    }
    private var scoreConversation: Double = 0 {
        didSet {
            scoreConversation = round(scoreConversation * 10) / 10
        }
    }
    private var scorePersonal: Double = 0 {
        didSet {
            scorePersonal = round(scorePersonal * 10) / 10
        }
    }
    private var scoreEmotional: Double = 0 {
        didSet {
            scoreEmotional = round(scoreEmotional * 10) / 10
        }
    }
    
    private var scoreSmiling: Double = 0 {
        didSet {
            scoreSmiling = round(scoreSmiling * 10) / 10
        }
    }
    
    // date formatter
    let dFormatter = DateFormatter()

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Setup Date Format
        dFormatter.dateStyle = .medium
        dFormatter.timeStyle = .none
        
        if snapshot != nil {
            loadData()
        } else {
            clearCell()
        }
    }
    
    private func loadData() {
        var cellShouldConfigure: Bool = false
        
        guard snapshot != nil else { return }
        let date = snapshot.date

        let friend = snapshot.friend
        let idea = snapshot.getTopLevelScoreValue(forSummaryItem: .ideaEngagement) ?? 0
        let conversation = snapshot.getTopLevelScoreValue(forSummaryItem: .conversationEngagement) ?? 0
        let personal = snapshot.getTopLevelScoreValue(forSummaryItem: .personalConnection) ?? 0
        let emotional = snapshot.getTopLevelScoreValue(forSummaryItem: .emotionalConnection) ?? 0
        let smiling = snapshot.getTopLevelScoreValue(forSummaryItem: .smilingPercentage) ?? 0
        
        if friend != friendName {
            friendName = friend
            cellShouldConfigure = true
        }
        
        if date != self.date {
            self.date = date
            cellShouldConfigure = true
        }
        
        var dateString: String = "[Error: Invalid Date]"
        if let date = self.date {
            dateString = dFormatter.string(from: date)
        }
        
        let newTitle = "Conversation with \(friendName) on \(dateString)"
        if newTitle != title {
            title = newTitle
            cellShouldConfigure = true
        }
        
        if scoreIdea != idea {
            scoreIdea = idea
            cellShouldConfigure = true
        }
        
        if scoreConversation != conversation {
            scoreConversation = conversation
            cellShouldConfigure = true
        }
        
        if scorePersonal != personal {
            scorePersonal = personal
            cellShouldConfigure = true
        }
        
        if scoreEmotional != emotional {
            scoreEmotional = emotional
            cellShouldConfigure = true
        }
        
        if scoreSmiling != smiling {
            scoreSmiling = smiling
            cellShouldConfigure = true
        }
        
        if cellShouldConfigure {
            configureCell()
        }
        
    }
    
    private func configureCell() {
        lblSummaryTitle.text = title
        configureChart()
        setNeedsLayout()
    }
    
    private func configureChart() {
        let mindAverage = (scoreIdea + scoreConversation) / 2.0
        let heartAverage = (scorePersonal + scoreEmotional + scoreSmiling) / 3.0
        
        setup(chartView: mindChart, withScore: mindAverage, andColor: #colorLiteral(red: 0.4862745098, green: 0.7098039216, blue: 0.9254901961, alpha: 1))
        setup(chartView: heartChart, withScore: heartAverage, andColor: #colorLiteral(red: 0.4941176471, green: 0, blue: 0, alpha: 1))
    }
    
    private func setup(chartView: HIChartView, withScore score: Double, andColor color: UIColor) {
        // Initialize Chart Options
        let options = HIOptions()
        
        // tooltip
        let tooltip = HITooltip()
        tooltip.enabled = false
        
        // Setup Chart
        let chart = HIChart()
        chart.type = "solidgauge"
        
        // title
        let title = HITitle()
        title.text = ""
        
        // hide hamburger button
        let navigation = HINavigation()
        let buttonOptions = HIButtonOptions()
        buttonOptions.enabled = false
        navigation.buttonOptions = buttonOptions
        
        // pane
        let pane = HIPane()
        pane.startAngle = 0
        pane.endAngle = 360
        
        // pane background
        let paneBackground = HIBackground()
        paneBackground.outerRadius = "100%"
        paneBackground.innerRadius = "70%"
        paneBackground.borderWidth = 0
        let bgColor = color.withAlphaComponent(0.35)
        let bgColorString = getHex(for: bgColor)
        let backgroundColor = HIGradientColorObject()
        backgroundColor.linearGradient = HILinearGradientColorObject()
        backgroundColor.linearGradient.y1 = 0
        backgroundColor.linearGradient.y2 = 1
        backgroundColor.stops = [
            [0, bgColorString],
            [1, bgColorString]
        ]
        paneBackground.backgroundColor = backgroundColor
        
        pane.background = [paneBackground]
        
        // y axis
        
        let yAxis = HIYAxis()
        let yTitle = HITitle()
        yTitle.text = "\(round(score * 10) / 10)"
        yTitle.style = HICSSObject()
        yTitle.style.fontWeight = "bold"
        yTitle.style.fontSize = "20"
        let center = chartView.bounds.height / 4 - 5
        yTitle.y = center as NSNumber
        yAxis.min = 0
        yAxis.max = 100
        yAxis.lineWidth = 0
        yAxis.tickPosition = ""
        yAxis.tickAmount = 0
        yAxis.tickPositions = []
        yAxis.title = yTitle
        
        // plot options
        let plotOptions = HIPlotOptions()
        plotOptions.solidgauge = HISolidgauge()
        let labelsOptions = HIDataLabelsOptionsObject()
        labelsOptions.enabled = false
        plotOptions.solidgauge.dataLabels = [labelsOptions]
        plotOptions.solidgauge.linecap = "round"
        plotOptions.solidgauge.stickyTracking = false
        plotOptions.solidgauge.rounded = true
        
        let gage = HISolidgauge()
        gage.name = ""
        let data = HIData()
        data.color = HIColor(uiColor: color)
        data.radius = "100%"
        data.innerRadius = "70%"
        let percent = (score / 10 * 100)
        data.y = percent as NSNumber
        gage.data = [data]
        
        options.chart = chart
        options.title = title
        options.tooltip = tooltip
        options.pane = pane
        options.yAxis = [yAxis]
        options.plotOptions = plotOptions
        options.series = [gage]
        options.credits = HICredits()
        options.credits.enabled = false
        options.navigation = navigation
        
        chartView.options = options
    }
    
    private func getHex(for color: UIColor) -> String {
        let ciColor = CIColor(color: color)
        let r = Int(ciColor.red * 255.0)
        let g = Int(ciColor.green * 255.0)
        let b = Int(ciColor.blue * 255.0)
        let a = Int(ciColor.alpha * 255.0)
        
        return "#" + String(format: "%02x%02x%02x%02x", r, g, b, a)
    }
    
    private func clearCell() {
        lblSummaryTitle.text = "Loading..."
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
