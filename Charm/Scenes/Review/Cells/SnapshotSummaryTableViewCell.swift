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
    @IBOutlet weak var viewChart: HIChartView!
    @IBOutlet weak var lblScoreIdea: UILabel!
    @IBOutlet weak var lblScoreConversation: UILabel!
    @IBOutlet weak var lblScorePersonal: UILabel!
    @IBOutlet weak var lblScoreEmotional: UILabel!
    @IBOutlet weak var lblScoreSmiling: UILabel!
    
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
        lblScoreIdea.text = "\(scoreIdea)/10"
        lblScoreConversation.text = "\(scoreConversation)/10"
        lblScorePersonal.text = "\(scorePersonal)/10"
        lblScoreEmotional.text = "\(scoreEmotional)/10"
        lblScoreSmiling.text = "\(scoreSmiling)/10"
        configureChart()
        setNeedsLayout()
    }
    
    private func configureChart() {
        let mindAverage = (scoreIdea + scoreConversation) / 2.0
        let heartAverage = (scorePersonal + scoreEmotional + scoreSmiling) / 3.0
        
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
        
        // pane background for mind
        let paneBackground1 = HIBackground()
        paneBackground1.outerRadius = "100%"
        paneBackground1.innerRadius = "70%"
        paneBackground1.borderWidth = 0

        let bgColor1 = #colorLiteral(red: 0.4862745098, green: 0.7098039216, blue: 0.9254901961, alpha: 0.35)
        let color1 = #colorLiteral(red: 0.4862745098, green: 0.7098039216, blue: 0.9254901961, alpha: 1)
        let bgColorString1 = getHex(for: bgColor1)
        let backgroundColor1 = HIGradientColorObject()
        backgroundColor1.linearGradient = HILinearGradientColorObject()
        backgroundColor1.linearGradient.y1 = 0
        backgroundColor1.linearGradient.y2 = 1
        backgroundColor1.stops = [
            [0, bgColorString1],
            [1, bgColorString1]
        ]
        
        paneBackground1.backgroundColor = backgroundColor1
        
        // pane background for heart
        let paneBackground2 = HIBackground()
        paneBackground2.outerRadius = "70%"
        paneBackground2.innerRadius = "40%"
        paneBackground2.borderWidth = 0

        let bgColor2 = #colorLiteral(red: 0.4941176471, green: 0, blue: 0, alpha: 0.35)
        let color2 = #colorLiteral(red: 0.4941176471, green: 0, blue: 0, alpha: 1)
        let bgColorString2 = getHex(for: bgColor2)
        let backgroundColor2 = HIGradientColorObject()
        backgroundColor2.linearGradient = HILinearGradientColorObject()
        backgroundColor2.linearGradient.y1 = 0
        backgroundColor2.linearGradient.y2 = 1
        backgroundColor2.stops = [
            [0, bgColorString2],
            [1, bgColorString2]
        ]
        paneBackground2.backgroundColor = backgroundColor2
        
        pane.background = [paneBackground1, paneBackground2]
        
        // y axis and title
        let yAxis = HIYAxis()
        let yTitle = HITitle()
        yTitle.text = ""
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
        
        // setup data for mind
        let gage1 = HISolidgauge()
        gage1.name = ""
        let data1 = HIData()
        data1.color = HIColor(uiColor: color1)
        data1.radius = "100%"
        data1.innerRadius = "70%"
        let percent1 = (mindAverage / 10 * 100)
        data1.y = percent1 as NSNumber
        gage1.data = [data1]
        
        // setup data for heart
        let gage2 = HISolidgauge()
        gage2.name = ""
        let data2 = HIData()
        data2.color = HIColor(uiColor: color2)
        data2.radius = "70%"
        data2.innerRadius = "40%"
        let percent2 = (heartAverage / 10 * 100)
        data2.y = percent2 as NSNumber
        gage2.data = [data2]
        
        options.chart = chart
        options.title = title
        options.tooltip = tooltip
        options.pane = pane
        options.yAxis = [yAxis]
        options.plotOptions = plotOptions
        options.series = [gage1, gage2]
        options.credits = HICredits()
        options.credits.enabled = false
        options.navigation = navigation
        
        viewChart.options = options
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
        lblScoreIdea.text = "..."
        lblScoreConversation.text = "..."
        lblScorePersonal.text = "..."
        lblScoreEmotional.text = "..."
        lblScoreSmiling.text = "..."
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
