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
    
    // data chart will be built with
    var snapshot: Snapshot!
    var feedback: String? = nil
    
    // Data for filling tableview cells
    var transcript: [TranscriptCellInfo] = []
    var sliderData: [SliderCellInfo] = []
    var calloutData: [String] = []
    
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
    
    // make sure to not accidentally tap on more info button
    var isTableViewScrolling: Bool = false
    
    // MARK: - View Lifecycle Functions

    override func viewDidLoad() {
        super.viewDidLoad()
        
        chartView.plugins = ["annotations"]
//        chartView.layer.masksToBounds = false
//        chartView.layer.shadowColor = UIColor.black.cgColor
//        chartView.layer.shadowRadius = 1
//        chartView.layer.shadowOffset = CGSize(width: 0, height: 1)
//        chartView.layer.shadowOpacity = 0.5
        
        if let delegate = UIApplication.shared.delegate as? AppDelegate, let window = delegate.window, let nav = window.rootViewController as? UINavigationController {
            let constant = nav.navigationBar.frame.height
            chartViewHeight.constant = constant
            view.setNeedsLayout()
            view.layoutIfNeeded()
        }

        // setup date formatter
        dFormatter.dateStyle = .medium
        
        // load summary data
        if let data = UserSnapshotData.shared.selectedSnapshot {
            snapshot = data
        } else if let data = UserSnapshotData.shared.snapshots.first {
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
        if let newSnapshot = UserSnapshotData.shared.selectedSnapshot {
            snapshot = newSnapshot
        }
        
        guard snapshot != nil else { return }
        loadData()
        setupChart()
    }
    
    @objc private func infoButtonTapped() {
        guard let info = storyboard?.instantiateViewController(withIdentifier: StoryboardID.Info) as? InfoDetailViewController else { return }
        var type: InfoDetail = .Connection
        
        switch chartType! {
        case .Connection:
            type = .Connection
        case .Conversation:
            type = .Conversation
        case .Emotions:
            type = .Emotions
        case .IdeaEngagement:
            type = .Ideas
        }
        
        info.type = type
        tabBarController?.navigationController?.pushViewController(info, animated: true)
    }
    
    private func loadData() {
                
        // clear any old values
        chartData = []
        sliderData = []
        transcript = []
        
        // setup data based on type
        switch chartType! {
        case .IdeaEngagement:
            
            let ideaEngagement = snapshot.ideaEngagement
            
            // setup chart data
            for (index, item) in ideaEngagement.enumerated() {
                let point = HIPoint()
                point.x = index as NSNumber
                point.y = item.score as NSNumber
                calloutData.append(item.word)
                chartData.append(point)
                let tag = item.isConcrete ? "Concrete" : "Abstract"
                transcript.append(TranscriptCellInfo(withText: "[\(index)]: \(item.word) (\(tag))"))
            }
            
            // setup slider bar data
            if let position = snapshot.getTopLevelRawValue(forSummaryItem: .IdeaEngagement), let score = snapshot.getTopLevelScoreValue(forSummaryItem: .IdeaEngagement) {
                let cellInfo = SliderCellInfo(details: SliderDetails(type: .fillFromLeft), title: "Estimated Idea Engagement", score: score, position: CGFloat(position))
                sliderData.append(cellInfo)
            }
            
            if let position = snapshot.getTopLevelRawValue(forSummaryItem: .Concrete), let score = snapshot.getTopLevelRankValue(forSummaryItem: .Concrete) {
                let cellInfo = SliderCellInfo(details: SliderDetails(type: .fixed, valueType: .percent, minBlue: 0.33, maxBlue: 0.67), title: "Concrete Details(%)", score: score, position: CGFloat(position))
                sliderData.append(cellInfo)
            }
            
            // get feedback text
            feedback = snapshot.getTopLevelFeedback(forSummaryItem: .IdeaEngagement)
            
        case .Conversation:
            let conversation = snapshot.conversation
            // setup chart data
            
            var isTranscriptLoaded: Bool = false
            if let trans = snapshot.transcript {
                var position = 0
                for phrase in trans {
                    let person: String = phrase.person != nil ? phrase.person! : "Unknown"
                    
                    transcript.append(TranscriptCellInfo(withText: "[\(person)]: \(phrase.words)", at: position))
                    position += phrase.words.numberOfWords
                }
                isTranscriptLoaded = true
            }
            
            
            for (index, item) in conversation.enumerated() {
                let point = HIPoint()
                point.x = index as NSNumber
                
                if let value = item.adjustedAvg {
                    point.y = value as NSNumber
                } else {
                    point.y = 0
                }
            
                let text = "[\(String(describing: item.person))]: \(item.word)"
                
                calloutData.append(item.word)
                chartData.append(point)
                
                // no need to do this if the transcript is aleady loaded
                if isTranscriptLoaded { continue }
                transcript.append(TranscriptCellInfo(withText: text))
                
            }
            
            // setup slider bar data
            if let position = snapshot.getTopLevelRawValue(forSummaryItem: .ConversationEngagement), let score = snapshot.getTopLevelScoreValue(forSummaryItem: .ConversationEngagement) {
                let cellInfo = SliderCellInfo(details: SliderDetails(type: .fillFromLeft), title: "Estimated Conversation Engagement", score: score, position: CGFloat(position))
                sliderData.append(cellInfo)
            }
            
            if let position = snapshot.getTopLevelRawValue(forSummaryItem: .TalkingPercentage), let score = snapshot.getTopLevelRankValue(forSummaryItem: .TalkingPercentage) {
                let cellInfo = SliderCellInfo(details: SliderDetails(type: .fixed, valueType: .percent, minBlue: 0.33, maxBlue: 0.67), title: "Talking(%)", score: score, position: CGFloat(position))
                sliderData.append(cellInfo)
            }
            
            // get feedback text
            feedback = snapshot.getTopLevelFeedback(forSummaryItem: .ConversationEngagement)
            
        case .Connection:
            let connection = snapshot.connection
            // setup chart data
            for (index, item) in connection.enumerated() {
                // add transcript data
                let pronoun = Pronoun.init(rawValue: item.classification) ?? .FirstPerson
                let text = "[\(index)]: \(item.word) (\(pronoun.description))"
                transcript.append(TranscriptCellInfo(withText: text))
                
                let point = HIPoint()
                point.x = index as NSNumber
                if let value = item.adjustedAverage {
                    point.y = value as NSNumber
                } else {
                    point.y = 0
                }
                
                calloutData.append(item.word)
                chartData.append(point)
            }
            
            // setup slider bar data
            if let position = snapshot.getTopLevelRawValue(forSummaryItem: .PersonalConnection), let score = snapshot.getTopLevelScoreValue(forSummaryItem: .PersonalConnection) {
                let cellInfo = SliderCellInfo(details: SliderDetails(type: .fillFromLeft), title: "Estimated Personal Engagement", score: score, position: CGFloat(position))
                sliderData.append(cellInfo)
            }
            
            if let position = snapshot.getTopLevelRawValue(forSummaryItem: .FirstPerson), let score = snapshot.getTopLevelRankValue(forSummaryItem: .FirstPerson) {
                let cellInfo = SliderCellInfo(details: SliderDetails(type: .fixed, valueType: .percent, minBlue: 0.375, maxBlue: 0.625), title: "First Person(%)", score: score, position: CGFloat(position))
                sliderData.append(cellInfo)
            }
            
            // get feedback text
            feedback = snapshot.getTopLevelFeedback(forSummaryItem: .PersonalConnection)
        
        case .Emotions:
            posData = []
            negData = []
            let toneGraph = snapshot.graphTone
            let toneTable = snapshot.tableViewTone
            // setup chart data
            for (index, item) in toneGraph.enumerated() {
                
                let dataPoint = HIPoint()
                let posPoint = HIPoint()
                let negPoint = HIPoint()
                
                dataPoint.x = index as NSNumber
                posPoint.x = index as NSNumber
                negPoint.x = index as NSNumber
                
                dataPoint.y = item.roll3 as NSNumber
                posPoint.y = item.rollPos3 as NSNumber
                negPoint.y = item.rollNeg3 as NSNumber
                
                chartData.append(dataPoint)
                posData?.append(posPoint)
                negData?.append(negPoint)
            }
            
            // setup scale bar data
            if let position = snapshot.getTopLevelRawValue(forSummaryItem: .EmotionalConnection), let score = snapshot.getTopLevelScoreValue(forSummaryItem: .EmotionalConnection) {
                let cellInfo = SliderCellInfo(details: SliderDetails(type: .fillFromLeft), title: "Estimated Emotional Connection", score: score, position: CGFloat(position))
                sliderData.append(cellInfo)
            }
            
            if let position = snapshot.getTopLevelRawValue(forSummaryItem: .PositiveWords), let score = snapshot.getTopLevelRankValue(forSummaryItem: .PositiveWords) {
                let cellInfo = SliderCellInfo(details: SliderDetails(type: .fixed, valueType: .percent, minBlue: 0.67, maxBlue: 1.0), title: "Positive Word(%)", score: score, position: CGFloat(position))
                sliderData.append(cellInfo)
            }
            
            if let position = snapshot.getTopLevelRawValue(forSummaryItem: .NegativeWords), let score = snapshot.getTopLevelRankValue(forSummaryItem: .NegativeWords) {
                let cellInfo = SliderCellInfo(details: SliderDetails(type: .fixed, valueType: .percent, minBlue: 0.0, maxBlue: 0.0, minRed: 0.9, maxRed: 1.0), title: "Negative Word(%)", score: score, position: CGFloat(position))
                sliderData.append(cellInfo)
            }
            
            // setup transcript data
            for (index, item) in toneTable.enumerated() {
                let text = "[\(index)]: \(item.word) (Score: \(item.score))"
                transcript.append(TranscriptCellInfo(withText: text))
            }
            
            // get feedback text
            feedback = snapshot.getTopLevelFeedback(forSummaryItem: .EmotionalConnection)
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
        
        switch chartType! {
        case .IdeaEngagement:
            colorArray = [
                [NSNumber(value: 0), "rgb(242, 0, 0, 1)"],
                [NSNumber(value: 0.2), "rgba(242, 0, 0, 0)"],
                [NSNumber(value: 0.85), "rgba(128, 0, 0, 0)"],
                [NSNumber(value: 1), "rgb(86, 0 , 0, 1)"]
            ]
            
            yaxis.min = -1.0
            yaxis.max = 1.0
            yaxis.tickInterval = 0.2
            
            lowerBoundValue = -0.5
            upperBoundValue = 0.5
        case .Conversation:
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
        case .Connection:
            colorArray = [
//                [NSNumber(value: 0), "rgb(86, 0 ,0)"],
//                [NSNumber(value: 0.5), "rgba(216,0,0, 0)"],
//                [NSNumber(value: 0.7), "rgba(47,0,0,0)"],
//                [NSNumber(value: 1), "rgb(255, 0 ,0)"]
                [NSNumber(value: 0), "rgb(242, 0, 0, 1)"],
                [NSNumber(value: 0.15), "rgba(242, 0, 0, 0)"],
                [NSNumber(value: 0.85), "rgba(128, 0, 0, 0)"],
                [NSNumber(value: 1), "rgb(86, 0 , 0, 1)"]
            ]
            
            yaxis.min = -1.05
            yaxis.max = 1.05
            yaxis.tickInterval = 0.21
            
            lowerBoundValue = -0.5
            upperBoundValue = 0.5
        case .Emotions:
            colorArray = [
                [NSNumber(value: 0.0), "rgb(0, 242, 0, 1)"],
                [NSNumber(value: 0.2), "rgb(0, 242, 0, 0)"],
                [NSNumber(value: 0.8), "rgb(242, 0, 0, 0)"],
                [NSNumber(value: 1.0), "rgb(242, 0, 0, 1)"]
                
//                [NSNumber(value: 0), "rgb(0, 242, 0, 1)"],
//                [NSNumber(value: 0.2), "rgba(0, 242, 0, 0)"],
//                [NSNumber(value: 0), "rgb(242, 0, 0)"],
//                [NSNumber(value: 0.15), "rgba(242, 0, 0, 0)"],
//                [NSNumber(value: 0.7), "rgba(80,216,0,0)"],
//                [NSNumber(value: 1), "rgba(80,216,0,1)"]
            ]
            yaxis.min = -0.4
            yaxis.max = 0.4
            yaxis.tickInterval = 0.08
            
            lowerBoundValue = 0.45
            upperBoundValue = 0.8
        }
        
        let options = HIOptions()
        let title = HITitle()
        title.reserveSpace = false
        title.text = ""
        
        let chart = HIChart()
        chart.zoomType = "x"
        
        yaxis.title = HITitle()
        yaxis.title.text = ""
        yaxis.title.reserveSpace = false
        yaxis.gridLineWidth = 0
        yaxis.labels = HILabels()
        yaxis.labels.enabled = false
        yaxis.visible = true
        
        if chartType != .Emotions {
            let upperBounds = HIPlotLines()
            upperBounds.color = HIColor(hexValue: "e4e4e4")
            upperBounds.width = 2
            upperBounds.value = upperBoundValue as NSNumber
//            upperBounds.zIndex = 5
            let upperlLabel = HILabel()
            upperlLabel.text = "Upper Boundary"
            upperlLabel.style = HICSSObject()
            upperlLabel.style.color = "#e4e4e4"
            upperBounds.label = upperlLabel
            
            let lowerBounds = HIPlotLines()
            lowerBounds.color = HIColor(hexValue: "e4e4e4")
            lowerBounds.width = 2
            lowerBounds.value = lowerBoundValue as NSNumber
//            lowerBounds.zIndex = 5
            let lowerLabel = HILabel()
            lowerLabel.text = "Lower Bondary"
            lowerLabel.style = HICSSObject()
            lowerLabel.style.color = "#e4e4e4"
            lowerLabel.y = 12
            lowerBounds.label = lowerLabel
            
            let centerLine = HIPlotLines()
            centerLine.color = HIColor(hexValue: "e4e4e4")
            centerLine.width = 2
            centerLine.value = 0
            
            yaxis.plotLines = [upperBounds, centerLine, lowerBounds]
        } else {
            let centerLine = HIPlotLines()
            centerLine.color = HIColor(hexValue: "e4e4e4")
            centerLine.width = 2
            centerLine.value = 0
            yaxis.plotLines = [centerLine]
        }
        
        
        
        let legend = HILegend()
        legend.enabled = false
        
        let plotoptions = HIPlotOptions()
        plotoptions.area = HIArea()
        if chartType != .Emotions {
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
        let clickClosure: HIClosure =  { (context: HIChartContext?) in
            if let row = context?.getProperty("this.x") as? Int {
                var shouldScroll = false
                var indexPath: IndexPath = IndexPath(row: 0, section: 0)
                switch self.chartType! {
                case .Emotions:
                    let tone = self.snapshot.graphTone[row]
                    print("~>Word is: \(tone.word)")
                    var didFind = false
                    for (index, tableItem) in self.snapshot.tableViewTone.enumerated() {
                        if tableItem.word == tone.word && tone.roll3 == tableItem.roll3 && tone.rollNeg3 == tableItem.rollNeg3 && tone.rollPos3 == tableItem.rollPos3 {
                            indexPath = IndexPath(row: index, section: 1)
                            didFind = true
                            shouldScroll = true
                            break
                        }
                    }
                    
                    if !didFind {
                        // create our own annotation
                        
                        // remove any old annotations
                        self.chartView.removeAnnotation(byId: "annotation")
                        
                        // create new one
                        let annotations = HIAnnotations()
                        annotations.labels = [HILabels]()
                        let label = HILabels()
                        label.align = "top"
                        label.point = HIPoint()
                        label.point.xAxis = 0
                        label.point.yAxis = 0
                        label.point.x = row as NSNumber
                        
                        if let yValue = context?.getProperty("this.y") as? NSNumber {
                            label.point.y = yValue
                        } else {
                            label.point.y = tone.roll3 as NSNumber
                        }
                        
                        label.text = tone.word
                        annotations.labels.append(label)
                        annotations.id = "annotation"
                        
                        self.chartView.addAnnotation(annotations, redraw: true)
                        
                        if self.timer.isValid { self.timer.invalidate() }
                        
                        self.timer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false, block: { (_) in
                            self.chartView.removeAnnotation(byId: "annotation")
                        })
                    }
                case .Conversation:
                    guard let first = self.transcript.first, first.position != nil else { fallthrough }
                    var currentPosition: Int = 0
                    var previousIndex: Int = 0
                    for (index, trans) in self.transcript.enumerated() {
                        guard let position = trans.position else { continue }
                        currentPosition = position
                        if currentPosition == row {
                            indexPath = IndexPath(row: index, section: 1)
                            shouldScroll = true
                            break
                        } else if row < currentPosition {
                            indexPath = IndexPath(row: previousIndex, section: 1)
                            shouldScroll = true
                            break
                        }
                        
                        previousIndex = index
                    }
                    
                default:
                    indexPath = IndexPath(row: row, section: 1)
                    shouldScroll = true
                }
                
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
            
//            let shadow = HIShadowOptionsObject()
//
//            area.shadow = shadow
//            posArea.shadow = shadow
//            negArea.shadow = shadow
            
            options.series = [area, posArea, negArea]
            legend.enabled = false
        } else {
//            let shadow = HIShadowOptionsObject()
//
//            area.shadow = shadow
            
            options.series = [area]
        }
        
//        chart.backgroundColor = HIColor(uiColor: .white)
//        chart.shadow = HICSSObject()
    
        let tooltip = HITooltip()
        tooltip.enabled = false
        options.chart = chart
        options.title = title
        options.legend = legend
        options.yAxis = [yaxis]
        
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
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            if let data = snapshot, let top = data.topLevelMetrics.first, top.feedback != nil {
                return sliderData.count + 1
            } else {
                return sliderData.count
            }
        default:
            return transcript.count
        }
    }
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        guard let _ = tableView.cellForRow(at: indexPath) as? AIFeedbackTableViewCell else { return }
        infoButtonTapped()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0:
            // see if we are setting up a scalebar or feedback
            var row = indexPath.row
            var setupFeedback: Bool = false
            if sliderData.count > 1 && row > 1 {
                row -= 1
            } else if sliderData.count > 1 && row == 1 {
                setupFeedback = true
            } else if row == sliderData.count {
                setupFeedback = true
            }
            
            if setupFeedback {
                let cell = tableView.dequeueReusableCell(withIdentifier: CellID.AIFeedbback, for: indexPath) as! AIFeedbackTableViewCell
                guard let feedback = self.feedback else { return cell }
                cell.feedbackText = feedback
                cell.accessoryType = .detailButton
                return cell
            }
            
            // setup scalebar
            let cell = tableView.dequeueReusableCell(withIdentifier: CellID.ScaleBar, for: indexPath) as! ScaleBarTableViewCell
            let info = sliderData[row]
            cell.lblDescription.text = info.title
            
            if info.details.hasRed {
                cell.sliderView.setup(for: info.details.type, at: info.position, minBlue: info.details.minBlue, maxBlue: info.details.maxBlue, minRed: info.details.minRedValue, maxRed: info.details.maxRedValue)
            } else {
                cell.sliderView.setup(for: info.details.type, at: info.position, minBlue: info.details.minBlue, maxBlue: info.details.maxBlue)
            }
            
            switch info.details.valueType {
            case .double:
                cell.lblScore.text = "\(info.score)"
            case .int:
                cell.lblScore.text = "\(Int(info.score))"
            case .percent:
//                let percentValue = Int(info.score * 100)
                cell.lblScore.text = info.percentString
            }
            
            return cell
        default:
            // setup transcript
            let cell = tableView.dequeueReusableCell(withIdentifier: CellID.Transcript, for: indexPath) as! TranscriptTableViewCell
            let info = transcript[indexPath.row]
            cell.lblTranscriptText.text = info.text
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(origin: .zero, size: CGSize(width: tableView.frame.width, height: 1)))
        view.backgroundColor = .clear
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        if !isTableViewScrolling, let _ = tableView.cellForRow(at: indexPath) as? AIFeedbackTableViewCell {
            infoButtonTapped()
        }
        
        if let _ = tableView.cellForRow(at: indexPath) as? TranscriptTableViewCell {
            // remove any old annotations
            chartView.removeAnnotation(byId: "annotation")
            guard chartView.options.series[0].data.count > indexPath.row else { return }
            
            var item: HIPoint = HIPoint()
            var word: String = ""
            
            if chartType! == .Emotions {
                // find the correct data point
                let toneGraph = snapshot.graphTone
                let rawItem = snapshot.tableViewTone[indexPath.row]
                for (index, toneItem) in toneGraph.enumerated() {
                    if toneItem.word == rawItem.word && toneItem.roll3 == rawItem.roll3
                        && toneItem.rollNeg3 == rawItem.rollNeg3 && toneItem.rollPos3 == rawItem.rollPos3 {
                        // item was found, link them and be done
                        item = chartView.options.series[0].data[index] as! HIPoint
                        word = toneItem.word
                    }
                }
            } else if chartType! == .Conversation, let first = transcript.first, first.position != nil {
                let transcriptItem = transcript[indexPath.row]
                guard let position = transcriptItem.position else { return }
                if chartView.options.series[0].data.count < position && calloutData.count < position {
                    if let itm = chartView.options.series[0].data.last as? HIPoint, let co = calloutData.last {
                        item = itm
                        word = co
                    } else {
                        return
                    }
                }
                item = chartView.options.series[0].data[position] as! HIPoint
                word = calloutData[position]
            } else {
                item = chartView.options.series[0].data[indexPath.row] as! HIPoint
            }

            let annotations = HIAnnotations()
            annotations.labels = [HILabels]()
            let label = HILabels()
            label.align = "auto"
            label.point = HIPoint()
            label.point.xAxis = 0
            label.point.yAxis = 0
            label.point.x = item.x
            
            
            let offset = 0.075
            if let yaxisarray = chartView.options.yAxis, let yaxis = yaxisarray.first, let max = yaxis.max, Double(truncating: item.y) > Double(truncating: max) - offset {
                print("~>Making it smaller.")
                label.point.y = NSNumber(value: Double(truncating: item.y) - offset)
            } else {
                label.point.y = item.y
            }
            
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
            if indexPath.row != 1 { fallthrough }
            let font = UIFont.systemFont(ofSize: 14)
            guard let text = feedback else { return 0 }
            let height = heightForView(text: text, font: font, width: tableView.frame.width - 40)
            let difference = height - 20
            
            return 54 + difference
        case 1:
            let font = UIFont.systemFont(ofSize: 14)
            guard transcript.count > indexPath.row else { return 64 }
            let text = transcript[indexPath.row].text
            let height = heightForView(text: text, font: font, width: tableView.frame.width - 40)
            let difference = height - 63.5
            return difference > 0 ? 64 + difference : 64
        default:
            return 64
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
