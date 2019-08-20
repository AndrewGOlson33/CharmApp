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
    private var scoreIdea: Int = 0
    private var scoreConversation: Int = 0
    private var scorePersonal: Int = 0
    private var scoreEmotional: Int = 0
    private var scoreSmiling: Int = 0
    
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
        let idea = Int(snapshot.getTopLevelScoreValue(forSummaryItem: .IdeaEngagement) ?? 0)
        let conversation = Int(snapshot.getTopLevelScoreValue(forSummaryItem: .ConversationEngagement) ?? 0)
        let personal = Int(snapshot.getTopLevelScoreValue(forSummaryItem: .PersonalConnection) ?? 0)
        let emotional = Int(snapshot.getTopLevelScoreValue(forSummaryItem: .EmotionalConnection) ?? 0)
        let smiling = Int(snapshot.getTopLevelScoreValue(forSummaryItem: .SmilingPercentage) ?? 0)
        
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
        // Setup Chart
        let options = HIOptions()
        let chart = HIChart()
        chart.polar = true
        viewChart.plugins = ["variable-pie"]
        chart.type = "variable-pie"
        let title = HITitle()
        title.text = ""
        
        // Create a legend so we can hide it
        let legend = HILegend()
        legend.enabled = false
        
        // Configure Pie Chart
        let plotoptions = HIPlotOptions()
        // Uncomment code to disable animations
//        plotoptions.series = HISeries()
//        let animation = HIAnimationOptionsObject()
//        animation.duration = 0
//        plotoptions.series.animation = animation
        
        let pie = HIVariablepie()
        pie.dataLabels = []
        let width: Double = 10
        
        pie.minPointSize = 10
        pie.innerSize = "20%"
        pie.zMin = 1
        
        pie.name = ""
        pie.data = [
            ["name": "Idea Engagement", "y": width, "z": scoreIdea.value(), "value": scoreIdea],
            ["name": "Conversation Engagement", "y": width, "z": scoreConversation.value(), "value": scoreConversation],
            ["name": "Personal Connection", "y": width, "z": scorePersonal.value(), "value": scorePersonal],
            ["name": "Emotional Connection", "y": width, "z": scoreEmotional.value(), "value": scoreEmotional],
            ["name": "Smiling %", "y": width, "z": scoreSmiling.value(), "value": scoreSmiling],
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
        options.legend = legend
        options.credits.enabled = false
        options.tooltip = HITooltip()
        options.tooltip.enabled = false
        options.chart.spacing = [0, 0, 0, 0]
        
        options.plotOptions = plotoptions
        options.series = NSMutableArray(objects: pie) as? [HISeries]
        
        viewChart.options = options
        print("~>Set chart options")
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
