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
    
    // Layout Constraint for Chart View
    @IBOutlet weak var chartViewHeight: NSLayoutConstraint!
    
    // MARK: - Properties
    
    var navTitle: String = ""
    var chartShowsText: String = ""
    
    // data chart will be built with
    var snapshot: Snapshot!
    var feedback: String? = nil
    var feedbackTrainingText: String = ""
    
    // Data for filling tableview cells
    var transcript: [TranscriptCellInfo] = []
    var sliderData: [SliderCellInfo] = []
    var calloutData: [String] = []
    var calloutInfo: [CalloutInfo] = []
    var calloutWord: String? = nil
    
    // date formatter for setting chart title
    let dFormatter = DateFormatter()
    
    // chart type (used to figure out which data to present)
    var chartType: ChartType!
    
    // data used for creating chart
    var chartData: [HIPoint] = []
    var posData: [HIPoint]? = nil
    var negData: [HIPoint]? = nil
    
    // Timer for hiding the annotation
    var timer = Timer()
    
    // Counter that helps animate scrolling
    var scrollCounter = 0
    
    // Helps deal with layout glitches caused by highcharts
    var chartDidLoad: Bool = false
    var viewHasAppeared: Bool = false
    
    // make sure to not accidentally tap on more info button
    var isTableViewScrolling: Bool = false
    
    // table view separator buffer
    let tableviewSpacing: CGFloat = 2
    
    // MARK: - View Lifecycle Functions

    override func viewDidLoad() {
        super.viewDidLoad()
        
        chartView.plugins = ["annotations"]
        
        if let delegate = UIApplication.shared.delegate as? AppDelegate, let window = delegate.window, let nav = window.rootViewController as? UINavigationController {
            let constant = nav.navigationBar.frame.height
            chartViewHeight.constant = constant
            view.setNeedsLayout()
            view.layoutIfNeeded()
        }

        // setup date formatter
        dFormatter.dateStyle = .medium
        
        // load summary data
        if let data = FirebaseModel.shared.selectedSnapshot {
            snapshot = data
        } else if let data = FirebaseModel.shared.snapshots.first {
            snapshot = data
        }
        
        // Resolve layout issues caused by highcharts
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.chartDidLoad = true
            self.tableView.reloadData()
        }

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.navigationItem.title = navTitle
        tabBarController?.navigationItem.rightBarButtonItem = nil
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // load a new snapshot if needed
        if let newSnapshot = FirebaseModel.shared.selectedSnapshot {
            snapshot = newSnapshot
        }
        
        guard snapshot != nil else { return }
        loadData()
        setupChart()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.viewHasAppeared = true
            self.tableView.reloadData()
        }
    }
    
    @objc private func infoButtonTapped() {
        guard let info = storyboard?.instantiateViewController(withIdentifier: StoryboardID.info) as? InfoDetailViewController else { return }
        var type: InfoDetail = .connection
        
        switch chartType! {
        case .connection:
            type = .connection
        case .conversation:
            type = .conversation
        case .emotions:
            type = .emotions
        case .ideaEngagement:
            type = .ideas
        }
        
        info.type = type
        tabBarController?.navigationController?.pushViewController(info, animated: true)
    }
    
    private func loadData() {
        // clear any old values
        chartData = []
        sliderData = []
        transcript = []
        calloutInfo = []
        
        // setup data based on type
        switch chartType! {
        case .ideaEngagement:
            let ideaEngagement = snapshot.ideaEngagement
            chartShowsText = FirebaseModel.shared.constants.metricDescWord
            feedbackTrainingText = FirebaseModel.shared.constants.metricTrainingWord
            
            // setup slider bar data
            if let position = snapshot.getTopLevelRawValue(forSummaryItem: .concrete), let score = snapshot.getTopLevelRankValue(forSummaryItem: .concrete) {
                let cellInfo = SliderCellInfo(details: SliderDetails(type: .fixed, valueType: .percent, start: 0.55, end: 0.75, color: #colorLiteral(red: 0.4862745098, green: 0.7098039216, blue: 0.9254901961, alpha: 1)), title: SliderCellTitle(description: "How Clearly You Are Understood", hint: "Recommended Range: 55% to 75%"), score: score, position: CGFloat(position))
                    
                sliderData.append(cellInfo)
            }
            
            if let position = snapshot.getTopLevelRawValue(forSummaryItem: .ideaEngagement), let score = snapshot.getTopLevelScoreValue(forSummaryItem: .ideaEngagement) {
                let cellInfo = SliderCellInfo(details: SliderDetails(type: .standard, color: #colorLiteral(red: 0.4862745098, green: 0.7098039216, blue: 0.9254901961, alpha: 1)), title: SliderCellTitle(description: "Engagement", hint: "Compared With the World’s Most Beloved Comedians"), score: score, position: CGFloat(position))
                
                sliderData.append(cellInfo)
            }
            
            // get feedback text
            feedback = snapshot.getTopLevelFeedback(forSummaryItem: .ideaEngagement)
            
            // setup transcript, chart data, and callout info
            guard ideaEngagement.count > 0 else { return }
            
            let maxIndex = ideaEngagement.count - 1
            var currentIndex = 0
            var currentItem = ideaEngagement[currentIndex]
            var shouldCheckWord = true
            
            // setup the transcript
            guard let trans = snapshot.transcript, let master = snapshot.master else { return }
            
            var position = 0
            for (tIndex, phrase) in trans.enumerated() {
                let isUser = phrase.person != snapshot.friend
                let start = position
                var current = start
                position += phrase.words.numberOfWords
                let phraseString: NSMutableAttributedString = NSMutableAttributedString()
                let components: [String] = phrase.words.components(separatedBy: " ")
                
                for word in components {
                    // check to see if this word is in the idea engagement array
                    if shouldCheckWord, isUser, word.contains(currentItem.word) {
                        let point = HIPoint()
                        point.x = currentIndex as NSNumber
                        point.y = currentItem.score as NSNumber
                        chartData.append(point)
                        calloutInfo.append(CalloutInfo(value: currentItem.word, transcriptIndex: tIndex))
                        
                        // update the current word
                        currentIndex += 1
                        if currentIndex > maxIndex { shouldCheckWord = false } else { currentItem = ideaEngagement[currentIndex] }
                    }
                    
                    let currentMaster = master[current]
                    current += 1
                    let attributes: [NSAttributedString.Key : Any]
                    if currentMaster.concrete {
                        attributes = [
                            .foregroundColor : UIColor.white,
                            .backgroundColor : #colorLiteral(red: 0.6784313725, green: 0.5803921569, blue: 0, alpha: 1)
                        ]
                    } else if currentMaster.abstract {
                        attributes = [
                            .foregroundColor : UIColor.white,
                            .backgroundColor : #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
                        ]
                    } else {
                        attributes = [.foregroundColor : UIColor.white]
                    }
                    
                    let currentWord = NSAttributedString(string: word, attributes: attributes)
                    phraseString.append(currentWord)
                    if current != position { phraseString.append(NSAttributedString(string: " ")) }
                }
                
                transcript.append(TranscriptCellInfo(withText: phraseString, isUser: isUser))
            }
        case .conversation:
            // setup label data
            chartShowsText = FirebaseModel.shared.constants.metricDescConvo
            feedbackTrainingText = FirebaseModel.shared.constants.metricTrainingConvo
            
            // setup slider bar data
            if let position = snapshot.getTopLevelRawValue(forSummaryItem: .talkingPercentage), let score = snapshot.getTopLevelRankValue(forSummaryItem: .talkingPercentage) {
                let cellInfo = SliderCellInfo(details: SliderDetails(type: .fixed, valueType: .percent, start: 0.42, end: 58, color: #colorLiteral(red: 0.4862745098, green: 0.7098039216, blue: 0.9254901961, alpha: 1)), title: SliderCellTitle(description: "How Much You Spoke", hint: "Recommended Range: 42% to 58%"), score: score, position: CGFloat(position))
                sliderData.append(cellInfo)
            }
            
            if let position = snapshot.getTopLevelRawValue(forSummaryItem: .conversationEngagement), let score = snapshot.getTopLevelScoreValue(forSummaryItem: .conversationEngagement) {
                let cellInfo = SliderCellInfo(details: SliderDetails(type: .standard, color: #colorLiteral(red: 0.4862745098, green: 0.7098039216, blue: 0.9254901961, alpha: 1)), title: SliderCellTitle(description: "Engagement", hint: "Compared With World's Most Beloved Television Shows"), score: score, position: CGFloat(position))
                sliderData.append(cellInfo)
            }
            
            // get feedback text
            feedback = snapshot.getTopLevelFeedback(forSummaryItem: .conversationEngagement)
            
            // setup transcript and chart data
            let conversation = snapshot.conversation
            guard conversation.count > 0 else { return }
            var position = 0
            let maxIndex = conversation.count - 1
            var currentIndex = 0
            var currentItem = conversation[currentIndex]
            guard let trans = snapshot.transcript else { return } // let master = snapshot.master
            
            for (tIndex, phrase) in trans.enumerated() {
                let isUser = phrase.person != snapshot.friend
                let start = position
                var current = start
                position += phrase.words.numberOfWords
                let phraseString: NSMutableAttributedString = NSMutableAttributedString()
                let components: [String] = phrase.words.components(separatedBy: " ")
                
                for word in components {
                    let point = HIPoint()
                    point.x = currentIndex as NSNumber
    
                    if let value = currentItem.adjustedAvg {
                        point.y = value as NSNumber
                    } else {
                        point.y = 0
                    }
                    
                    chartData.append(point)
                    calloutInfo.append(CalloutInfo(value: currentItem.word, transcriptIndex: tIndex))
                    
                    currentIndex += 1
                    if currentIndex <= maxIndex { currentItem = conversation[currentIndex] }
                    
                    // Uncomment if color coding
//                    let currentMaster = master[current]
                    current += 1
                    let attributes: [NSAttributedString.Key : Any]
                    
                    attributes = [.foregroundColor : UIColor.white]
                    
                    let currentWord = NSAttributedString(string: word, attributes: attributes)
                    phraseString.append(currentWord)
                    if current != position { phraseString.append(NSAttributedString(string: " ")) }
                }
                
                transcript.append(TranscriptCellInfo(withText: phraseString, isUser: isUser))
            }
            
        case .connection:
            // setup slider bar data
            if let position = snapshot.getTopLevelRawValue(forSummaryItem: .firstPerson), let score = snapshot.getTopLevelRankValue(forSummaryItem: .firstPerson) {
                let cellInfo = SliderCellInfo(details: SliderDetails(type: .fixed, valueType: .percent, start: 0.41, end: 0.59, color: #colorLiteral(red: 0.4862745098, green: 0.7098039216, blue: 0.9254901961, alpha: 1)), title: SliderCellTitle(description: "Who You Focused the Conversation On", hint: "Recommended Range: 41% to 59%"), score: score, position: CGFloat(position))
                sliderData.append(cellInfo)
            }
            
            if let position = snapshot.getTopLevelRawValue(forSummaryItem: .personalConnection), let score = snapshot.getTopLevelScoreValue(forSummaryItem: .personalConnection) {
                let cellInfo = SliderCellInfo(details: SliderDetails(type: .standard, color: #colorLiteral(red: 0.8509803922, green: 0.3490196078, blue: 0.3490196078, alpha: 1)), title: SliderCellTitle(description: "Connection", hint: "Compared With World’s Most Beloved Movie Scenes"), score: score, position: CGFloat(position))
                sliderData.append(cellInfo)
            }
            
            // get feedback text
            feedback = snapshot.getTopLevelFeedback(forSummaryItem: .personalConnection)
            
            // setup transcript and chart data
            let connection = snapshot.connection
            chartShowsText = FirebaseModel.shared.constants.metricDescPersonal
            feedbackTrainingText = FirebaseModel.shared.constants.metricTrainingPersonal
            
            guard connection.count > 0 else  { return }
            let maxIndex = connection.count - 1
            var currentIndex = 0
            var currentItem = connection[currentIndex]
            var shouldCheckWord = true
            
            guard let trans = snapshot.transcript, let master = snapshot.master else { return }
            var position = 0
            
            for (tIndex, phrase) in trans.enumerated() {
                let isUser = phrase.person != snapshot.friend
                let start = position
                var current = start
                position += phrase.words.numberOfWords
                let phraseString: NSMutableAttributedString = NSMutableAttributedString()
                let components: [String] = phrase.words.components(separatedBy: " ")
                
                for word in components {
                    // check to see if this word is in the idea engagement array
                    if shouldCheckWord, isUser, word.contains(currentItem.word) {
                        let point = HIPoint()
                        point.x = currentIndex as NSNumber
                        point.y = currentItem.adjustedAverage as NSNumber? ?? 0
                        chartData.append(point)
                        calloutInfo.append(CalloutInfo(value: currentItem.word, transcriptIndex: tIndex))
                        
                        // update the current word
                        currentIndex += 1
                        if currentIndex > maxIndex { shouldCheckWord = false } else { currentItem = connection[currentIndex] }
                    }
                    
                    let currentMaster = master[current]
                    current += 1
                    let attributes: [NSAttributedString.Key : Any]
                    
                    if currentMaster.firstPerson {
                        attributes = [
                            .foregroundColor : UIColor.white,
                            .backgroundColor : #colorLiteral(red: 0.1490196078, green: 0.5254901961, blue: 0.4862745098, alpha: 1)
                        ]
                    } else if currentMaster.secondPerson {
                        attributes = [
                            .foregroundColor : UIColor.white,
                            .backgroundColor : #colorLiteral(red: 0.4756349325, green: 0.4756467342, blue: 0.4756404161, alpha: 1)
                        ]
                    } else {
                        attributes = [.foregroundColor : UIColor.white]
                    }
                    
                    let currentWord = NSAttributedString(string: word, attributes: attributes)
                    phraseString.append(currentWord)
                    if current != position { phraseString.append(NSAttributedString(string: " ")) }
                }
                
                transcript.append(TranscriptCellInfo(withText: phraseString, isUser: isUser))
            }
        case .emotions:
            chartShowsText = FirebaseModel.shared.constants.metricDescEmotions
            feedbackTrainingText = FirebaseModel.shared.constants.metricTrainingEmotions
            posData = []
            negData = []
            let toneGraph = snapshot.graphTone
            
            // setup scale bar data
            if let position = snapshot.getTopLevelRawValue(forSummaryItem: .positiveWords), let score = snapshot.getTopLevelRankValue(forSummaryItem: .positiveWords) {
                let cellInfo = SliderCellInfo(details: SliderDetails(type: .fixed, valueType: .percent, start: 0.60, end: 1.0, color: #colorLiteral(red: 0.4862745098, green: 0.7098039216, blue: 0.9254901961, alpha: 1)), title: SliderCellTitle(description: "Positivity", hint: "Recommended Range: Greater Than 60%"), score: score, position: CGFloat(position))
                sliderData.append(cellInfo)
            }
            
            if let position = snapshot.getTopLevelRawValue(forSummaryItem: .negativeWords), let score = snapshot.getTopLevelRankValue(forSummaryItem: .negativeWords) {
                let cellInfo = SliderCellInfo(details: SliderDetails(type: .fixed, valueType: .percent, start: 0.9, end: 1.0, color: #colorLiteral(red: 0.8509803922, green: 0.3490196078, blue: 0.3490196078, alpha: 1)), title: SliderCellTitle(description: "Negativity", hint: "Recommended Range: Balance Out Positivity"), score: score, position: CGFloat(position))
                sliderData.append(cellInfo)
            }
            
            if let position = snapshot.getTopLevelRawValue(forSummaryItem: .emotionalConnection), let score = snapshot.getTopLevelScoreValue(forSummaryItem: .emotionalConnection) {
                let cellInfo = SliderCellInfo(details: SliderDetails(type: .standard, color: #colorLiteral(red: 0.8509803922, green: 0.3490196078, blue: 0.3490196078, alpha: 1)), title: SliderCellTitle(description: "Connection", hint: "Compared With World’s Most Beloved Politicians"), score: score, position: CGFloat(position))
                sliderData.append(cellInfo)
            }
            
            // get feedback text
            feedback = snapshot.getTopLevelFeedback(forSummaryItem: .emotionalConnection)
            
            // setup transcript, callout and chart data
            guard toneGraph.count > 0 else { return }
            
            var currentIndex = 0
            var currentItem = toneGraph[currentIndex]
           
            // setup the transcript
            guard let trans = snapshot.transcript, let master = snapshot.master else { return }

            var position = 0
            for (tIndex, phrase) in trans.enumerated() {
                let isUser = phrase.person != snapshot.friend
                let start = position
                var current = start
                position += phrase.words.numberOfWords
                let phraseString: NSMutableAttributedString = NSMutableAttributedString()
                let components: [String] = phrase.words.components(separatedBy: " ")

                for word in components {
                    
                    // load chart data
                    if isUser {
                        let dataPoint = HIPoint()
                        let posPoint = HIPoint()
                        let negPoint = HIPoint()

                        dataPoint.x = currentIndex as NSNumber
                        posPoint.x = currentIndex as NSNumber
                        negPoint.x = currentIndex as NSNumber

                        dataPoint.y = currentItem.roll3 as NSNumber
                        posPoint.y = currentItem.rollPos3 as NSNumber
                        negPoint.y = currentItem.rollNeg3 as NSNumber

                        chartData.append(dataPoint)
                        posData?.append(posPoint)
                        negData?.append(negPoint)

                        calloutInfo.append(CalloutInfo(value: currentItem.word, transcriptIndex: tIndex))

                        // update the current word
                        currentIndex += 1
                        if currentIndex < toneGraph.count { currentItem = toneGraph[currentIndex] }
                    }
                    
                    // setup transcript
                    let currentMaster = master[current]
                    current += 1
                    
                    let attributes: [NSAttributedString.Key : Any]
                    
                    if currentMaster.positiveWord {
                        attributes = [
                            .foregroundColor : UIColor.white,
                            .backgroundColor : #colorLiteral(red: 0, green: 0.7043033838, blue: 0.4950237274, alpha: 1)
                        ]
                    } else if currentMaster.negativeWord {
                        attributes = [
                            .foregroundColor : UIColor.white,
                            .backgroundColor : #colorLiteral(red: 0.8509803922, green: 0.3490196078, blue: 0.3490196078, alpha: 1)
                        ]
                    } else {
                        attributes = [.foregroundColor : UIColor.white]
                    }
                    
                    let currentWord = NSAttributedString(string: word, attributes: attributes)
                    phraseString.append(currentWord)
                    if current != position { phraseString.append(NSAttributedString(string: " ")) }
                }
                
                transcript.append(TranscriptCellInfo(withText: phraseString, isUser: isUser))
            }
        }
        
        tableView.reloadData()
    }
    
    private func setupChart() {
        
        // make sure there is data from summary
        guard snapshot != nil else {
            // Charts should not be accessable without data
            // however this case is handled with an overlay that gets set during load
            return
        }
        
        // Setup Chart
        
        // chart colors
        var colorArray: [[Any]] = []
        let yaxis = HIYAxis()
        
        var lowerBoundValue: Double
        var upperBoundValue: Double
        var upperBoundLabel: String = "\"Upper Bound\""
        var lowerBoundLabel: String = "\"Lower Bound\""
        
        switch chartType! {
        case .ideaEngagement:
            colorArray = [
//                [NSNumber(value: 0), "rgb(242, 0, 0, 1)"],
//                [NSNumber(value: 0.2), "rgba(242, 0, 0, 0)"],
//                [NSNumber(value: 0.85), "rgba(128, 0, 0, 0)"],
//                [NSNumber(value: 1), "rgb(86, 0 , 0, 1)"]
            ]
            
            yaxis.min = -1.0
            yaxis.max = 1.0
            yaxis.tickInterval = 0.2
            
            lowerBoundValue = -0.5
            upperBoundValue = 0.5
            upperBoundLabel = "\"Specific\""
            lowerBoundLabel = "\"Vague\""
        case .conversation:
            colorArray = [
                [NSNumber(value: 0), "rgb(242, 0, 0, 1)"],
                [NSNumber(value: 0.15), "rgba(242, 0, 0, 0)"],
                [NSNumber(value: 0.85), "rgba(128, 0, 0, 0)"],
                [NSNumber(value: 1), "rgb(86, 0 , 0, 1)"]
            ]
            yaxis.min = -1.05
            yaxis.max = 1.05
            yaxis.tickInterval = 0.21
            
            lowerBoundValue = -0.7
            upperBoundValue = 0.7
            upperBoundLabel = "\"Rambling\""
            lowerBoundLabel = "\"Quiet\""
        case .connection:
            colorArray = [
//                [NSNumber(value: 0), "rgb(242, 0, 0, 1)"],
//                [NSNumber(value: 0.15), "rgba(242, 0, 0, 0)"],
//                [NSNumber(value: 0.85), "rgba(128, 0, 0, 0)"],
//                [NSNumber(value: 1), "rgb(86, 0 , 0, 1)"]
            ]
            
            yaxis.min = -1.05
            yaxis.max = 1.05
            yaxis.tickInterval = 0.21
            
            lowerBoundValue = -0.5
            upperBoundValue = 0.5
            upperBoundLabel = "\"You\""
            lowerBoundLabel = "\"Me\""
        case .emotions:
            colorArray = [
                [NSNumber(value: 0.0), "rgb(0, 242, 0, 1)"],
                [NSNumber(value: 0.2), "rgb(0, 242, 0, 0)"],
                [NSNumber(value: 0.8), "rgb(242, 0, 0, 0)"],
                [NSNumber(value: 1.0), "rgb(242, 0, 0, 1)"]
            ]
            yaxis.min = -0.4
            yaxis.max = 0.4
            yaxis.tickInterval = 0.08
            
            lowerBoundValue = -0.3
            upperBoundValue = 0.3
            upperBoundLabel = "\"Good Things\""
            lowerBoundLabel = "\"Bad Things\""
        }
        
        let options = HIOptions()
        let title = HITitle()
        title.reserveSpace = false
        title.text = ""
        
        let chart = HIChart()
        chart.zoomType = "x"
        chart.backgroundColor = HIColor(uiColor: .clear)
        
        yaxis.title = HITitle()
        yaxis.title.text = ""
        yaxis.title.reserveSpace = false
        yaxis.gridLineWidth = 0
        yaxis.labels = HILabels()
        yaxis.labels.enabled = false
        yaxis.visible = true
        
        let boundColor: HIColor
        let boundColorString: String
        if #available(iOS 12.0, *) {
            if traitCollection.userInterfaceStyle == .light {
                boundColorString = "#797979"
                boundColor = HIColor(uiColor: #colorLiteral(red: 0.4745098039, green: 0.4745098039, blue: 0.4745098039, alpha: 1))
            } else {
                boundColorString = "#e4e4e4"
                boundColor = HIColor(uiColor: #colorLiteral(red: 0.8941176471, green: 0.8941176471, blue: 0.8941176471, alpha: 1))
            }
        } else {
            boundColorString = "#797979"
            boundColor = HIColor(uiColor: #colorLiteral(red: 0.4745098039, green: 0.4745098039, blue: 0.4745098039, alpha: 1))
        }
        
        let upperBounds = HIPlotLines()
        upperBounds.color = boundColor
        upperBounds.dashStyle = "Dash"
        upperBounds.width = 2
        upperBounds.value = upperBoundValue as NSNumber
        let upperlLabel = HILabel()
        upperlLabel.text = upperBoundLabel
        upperlLabel.style = HICSSObject()
        upperlLabel.style.color = boundColorString
        upperBounds.label = upperlLabel
        
        let lowerBounds = HIPlotLines()
        lowerBounds.color = boundColor
        lowerBounds.dashStyle = "Dash"
        lowerBounds.width = 2
        lowerBounds.value = lowerBoundValue as NSNumber
        let lowerLabel = HILabel()
        lowerLabel.text = lowerBoundLabel
        lowerLabel.style = HICSSObject()
        lowerLabel.style.color = boundColorString
        lowerLabel.y = 12
        lowerBounds.label = lowerLabel
        
        let centerLine = HIPlotLines()
        centerLine.color = boundColor
        centerLine.width = 2
        centerLine.value = 0
        
        yaxis.plotLines = [upperBounds, centerLine, lowerBounds]
        
        let legend = HILegend()
        legend.enabled = false
        
        let plotoptions = HIPlotOptions()
        plotoptions.area = HIArea()
        if chartType != .emotions {
            plotoptions.area.fillColor = HIColor(linearGradient: [
                "x1": NSNumber(value: 0),
                "x2": NSNumber(value: 0),
                "y1": NSNumber(value: 0),
                "y2": NSNumber(value: 1)
                ], stops: colorArray)
        }
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
        
        let events = HIEvents()
        let clickClosure: HIClosure =  { [weak self] (context: HIChartContext?) in
            guard let self = self else { return }
            let section = self.feedback == nil ? 2 : 3
            if let row = context?.getProperty("this.x") as? Int {
                var shouldScroll = false
                var indexPath: IndexPath = IndexPath(row: 0, section: 0)
                
                guard self.calloutInfo.count > row else { return }
                let tRow = self.calloutInfo[row].transcriptIndex
                self.calloutWord = self.calloutInfo[row].value
                indexPath = IndexPath(row: tRow, section: section)
                shouldScroll = true
                
                if shouldScroll {
                    self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .top)
                    self.tableView(self.tableView, didSelectRowAt: indexPath)
                }
                
                let point = self.chartView.options.series[0].data[row] as! HIPoint
                point.select(false)
            }
            
        }
        events.click = HIFunction(closure: clickClosure, properties: ["this.x", "this.y"])
        
        for point in area.data {
            guard let point = point as? HIPoint else {
                print("~>Not a point")
                continue
            }
            point.events = events
        }
        
        if let pos = posData, let neg = negData {
            let posArea = HIArea()
            let negArea = HIArea()
            area.name = "Emotional Connection Score"
            posArea.name = "Positive Word Score"
            negArea.name = "Negative Word Score"
            posArea.data = pos
            negArea.data = neg
            
            // setup interaction for pos and neg graphs
            for point in posArea.data {
                guard let point = point as? HIPoint else {
                    continue
                }
                point.events = events
            }
            
            for point in negArea.data {
                guard let point = point as? HIPoint else {
                    print("~>Not a point")
                    continue
                }
                point.events = events
            }
            
            area.fillColor = HIColor(linearGradient: [
                "x1": NSNumber(value: 0),
                "x2": NSNumber(value: 0),
                "y1": NSNumber(value: 0),
                "y2": NSNumber(value: 1)
                ], stops: colorArray)
            
            posArea.fillColor = HIColor(uiColor: .clear)
            
            negArea.fillColor = HIColor(uiColor: .clear)

            options.series = [area, posArea, negArea]
            legend.enabled = false
        } else {
            options.series = [area]
        }
    
        let tooltip = HITooltip()
        tooltip.enabled = false
        options.chart = chart
        options.title = title
        options.legend = legend
        options.yAxis = [yaxis]
        options.credits = HICredits()
        options.credits.enabled = false
        
        // make sure it can render more if needed
        if chartData.count > 1000 {
            plotoptions.series = HISeries()
            plotoptions.series.turboThreshold = chartData.count as NSNumber
        }
        
        options.plotOptions = plotoptions
        options.tooltip = tooltip
        
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
        return feedback == nil ? 3 : 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return sliderData.count
        case 2:
            if feedback == nil { fallthrough }
            return 1
        default:
            return transcript.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: CellID.chartTypeDetail, for: indexPath)
            cell.detailTextLabel?.text = chartShowsText
            return cell
        case 1:
            // setup scalebar
            let cell = tableView.dequeueReusableCell(withIdentifier: CellID.scaleBar, for: indexPath) as! ScaleBarTableViewCell
            let info = sliderData[indexPath.row]
            cell.lblDescription.text = info.title.description
            cell.lblHint.text = info.title.hint
            
            if !cell.sliderView.isSetup && viewHasAppeared {
                cell.sliderView.setup(for: info.details.type, atPosition: info.position, barStart: info.details.startValue, end: info.details.endValue, color: info.details.color)
                cell.sliderView.setNeedsLayout()
                
                UIView.animate(withDuration: 0.5) {
                    cell.sliderView.alpha = 1.0
                }
            } else if !viewHasAppeared {
                cell.sliderView.alpha = 0.0
            }
            
            cell.lblScore.text = info.positionPercent
            
            // if this is the last cell, just return it
            if indexPath.row == (sliderData.count - 1) {
                cell.separatorView.isHidden = true
            } else {
                cell.separatorView.isHidden = false
            }
            
            
            return cell
        case 2:
            if feedback == nil { fallthrough }
            let cell = tableView.dequeueReusableCell(withIdentifier: CellID.aiFeedbback, for: indexPath) as! AIFeedbackTableViewCell
            guard let feedback = self.feedback else { return cell }
            cell.feedbackText = feedback
            cell.recommendedTrainingText = feedbackTrainingText
            return cell
        default:
            // setup transcript
            let cell = tableView.dequeueReusableCell(withIdentifier: CellID.transcript, for: indexPath) as! TranscriptTableViewCell
            let info = transcript[indexPath.row]
            cell.setup(with: info)
            return cell
        }

    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(origin: .zero, size: CGSize(width: tableView.frame.width, height: 2)))
        let color: UIColor
        if #available(iOS 13.0, *) {
            color = .systemBackground
        } else {
            color = .white
        }
        
        view.backgroundColor = color
        let barView = UIView(frame: CGRect(x: 16, y: 0, width: view.frame.width - 32, height: view.frame.height))
        barView.backgroundColor = #colorLiteral(red: 0.7959883809, green: 0.7961289883, blue: 0.7959899306, alpha: 1)
        barView.layer.cornerRadius = 1
        view.addSubview(barView)
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return tableviewSpacing
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        if !isTableViewScrolling, let _ = tableView.cellForRow(at: indexPath) as? AIFeedbackTableViewCell {
            infoButtonTapped()
        }
        
        if let _ = tableView.cellForRow(at: indexPath) as? TranscriptTableViewCell {
            // remove any old annotations
            chartView.removeAnnotation(byId: "annotation")
            
            var item: HIPoint = HIPoint()
            var word: String = ""
            
            var idx: Int?
            if let cWord = calloutWord {
                idx = calloutInfo.firstIndex { $0.transcriptIndex == indexPath.row && $0.value == cWord }
                calloutWord = nil
            } else {
                idx = calloutInfo.firstIndex { $0.transcriptIndex == indexPath.row }
            }
            
            if idx == nil {
                let nIndex = calloutInfo.firstIndex { $0.transcriptIndex > indexPath.row }
                if let nextIndex = nIndex { idx = nextIndex - 1 }
            }
            
            guard let index = idx, index >= 0, chartData.count > index, calloutInfo.count > index else { return }
            
            item = chartData[index]
            word = calloutInfo[index].value
            
            let annotations = HIAnnotations()
            annotations.labels = [HILabels]()
            let label = HILabels()
            label.align = "auto"
            label.point = HIPoint()
            label.point.xAxis = 0
            label.point.yAxis = 0
            label.point.x = item.x
            
            let offset = 0.075
            
            if let chart = chartView, let options = chart.options, let yaxisarray = options.yAxis, let yaxis = yaxisarray.first, let max = yaxis.max, let itemYValue = item.y, Double(truncating: itemYValue) > Double(truncating: max) - offset {
                label.point.y = NSNumber(value: Double(truncating: item.y) - offset)
            } else {
                label.point.y = item.y
            }
            
            label.point.y = item.y
            
            if word.isEmpty && indexPath.row < calloutData.count {
                word = calloutData[indexPath.row]
            }
            
            label.text = word
            annotations.labels.append(label)
            annotations.id = "annotation"
            
            self.chartView.addAnnotation(annotations, redraw: true)
            
            if timer.isValid { timer.invalidate() }
            
            timer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false, block: { (_) in
                self.chartView.removeAnnotation(byId: "annotation")
            })
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return 50
        case 1:
            return indexPath.row == sliderData.count - 1 ? 80 : 82
        case 2:
            guard let text = feedback else { fallthrough }
            let font = UIFont.systemFont(ofSize: 14)
            let width = tableView.frame.width - 16
            let heightOne = heightForView(text: text, font: font, width: width)
            let heightTwo = heightForView(text: feedbackTrainingText, font: font, width: width)
            let height = heightOne + heightTwo
            let difference = height - 34
            return 100 + difference
        default:
            let font = UIFont.systemFont(ofSize: 14)
            guard transcript.count > indexPath.row else { return 64 }
            let text = transcript[indexPath.row].text
            let height = heightForView(text: text.mutableString as String, font: font, width: tableView.frame.width - 16)
            let difference = height - 17 + 16
            return difference > 0 ? 64 + difference : 64
        }
    }
    
    func heightForView(text:String, font:UIFont, width:CGFloat) -> CGFloat{
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: .greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = font
        label.text = text
        
        label.sizeToFit()
        return label.frame.height
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if let cell = tableView.visibleCells.first, let indexPath = tableView.indexPath(for: cell) {
            isTableViewScrolling = true
            tableView(tableView, didSelectRowAt: indexPath)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollCounter == 20, let cell = tableView.visibleCells.first, let indexPath = tableView.indexPath(for: cell) {
            tableView(tableView, didSelectRowAt: indexPath)
            scrollCounter = 0
        } else {
            scrollCounter += 1
        }
        
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if let cell = tableView.visibleCells.first, let indexPath = tableView.indexPath(for: cell) {
            tableView(tableView, didSelectRowAt: indexPath)
        }
        
        isTableViewScrolling = false
        scrollCounter = 0
    }
}
