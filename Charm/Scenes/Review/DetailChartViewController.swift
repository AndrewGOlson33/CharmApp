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
    @IBOutlet weak var viewNoSnapshots: UIView!
    
    // Layout Constraint for Chart View
    @IBOutlet weak var chartViewHeight: NSLayoutConstraint!
    
    // MARK: - Properties
    
    var navTitle: String = ""
    
    // data chart will be built with
    var snapshot: Snapshot!
    
    // Data for filling tableview cells
    var transcript: [TranscriptCellInfo] = []
    var scalebarData: [ScalebarCellInfo] = []
    
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
        if let data = UserSnapshotData.shared.selectedSnapshot {
            snapshot = data
        } else if let data = UserSnapshotData.shared.snapshots.first {
            snapshot = data
        } else {
            viewNoSnapshots.alpha = 0.0
            viewNoSnapshots.isHidden = false
            UIView.animate(withDuration: 0.25) {
                self.viewNoSnapshots.alpha = 1.0
            }
            return
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
    
    private func loadData() {
        // clear any old values
        chartData = []
        scalebarData = []
        transcript = []
        
        // setup data based on type
        switch chartType! {
        case .WordChoice:
            if !TrainingModelCapsule.shared.isModelLoaded {
                print("~>Not yet loaded...")
                chartView.showLoading("Loading")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.loadData()
                }
            } else {
                print("~>Loaded")
                chartView.hideLoading()
            }
            let wordChoice = snapshot.wordChoice
            TrainingModelCapsule.shared.checkTypes(from: wordChoice) { (types) in
                // setup chart data
                for (index, item) in wordChoice.enumerated() {
                    //                chartData.append([index, item.score])
                    let point = HIPoint()
                    point.x = index as NSNumber
                    point.y = item.score as NSNumber
                    self.chartData.append(point)
                    self.transcript.append(TranscriptCellInfo(withText: "[\(index)]: \(item.word) (\(types[index]))"))
                }
                
                // setup scale bar data
                if let engagementRaw = self.snapshot.getTopLevelRawValue(forSummaryItem: .WordChoice), let engagementLevel = self.snapshot.getTopLevelRawLevelValue(forSummaryItem: .WordChoice) {
                    let cellInfo = ScalebarCellInfo(type: .Green, title: "Estimated Engagement", score: engagementRaw, position: engagementLevel)
                    self.scalebarData.append(cellInfo)
                }
                
                if let concreteRaw = self.snapshot.getTopLevelRawValue(forSummaryItem: .ConcretePercentage), let concreteLevel = self.snapshot.getTopLevelRawLevelValue(forSummaryItem: .ConcretePercentage) {
                    let cellInfo = ScalebarCellInfo(type: .BlueRight, title: "Concrete Details(%)", score: concreteRaw, position: concreteLevel)
                    self.scalebarData.append(cellInfo)
                }
            }
            
            
        case .BackAndForth:
            let backAndForth = snapshot.backAndForth
            // setup chart data
            for (index, item) in backAndForth.enumerated() {
//                if let value = item.adjustedAvg {
//                    chartData.append([index, value])
//                } else {
//                    chartData.append([index, 0])
//                }
                
                let point = HIPoint()
                point.x = index as NSNumber
                
                if let value = item.adjustedAvg {
                    point.y = value as NSNumber
                } else {
                    point.y = 0
                }
                
                chartData.append(point)
            }
            
            // setup scale bar data
            if let engagementRaw = snapshot.getTopLevelRawValue(forSummaryItem: .BackAndForth), let engagementLevel = snapshot.getTopLevelRawLevelValue(forSummaryItem: .BackAndForth) {
                let cellInfo = ScalebarCellInfo(type: .Green, title: "Estimated Engagement", score: engagementRaw, position: engagementLevel)
                scalebarData.append(cellInfo)
            }
            
            if let talkingRaw = snapshot.getTopLevelRawValue(forSummaryItem: .Talking), let talkingLevel = snapshot.getTopLevelRawLevelValue(forSummaryItem: .Talking) {
                let cellInfo = ScalebarCellInfo(type: .BlueCenter, title: "Talking(%)", score: talkingRaw, position: talkingLevel)
                scalebarData.append(cellInfo)
            }
            
            // setup transcript
            for item in snapshot.transcript {
                let text = "[\(String(describing: item.person))]: \(item.words)"
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
                
                let point = HIPoint()
                point.x = index as NSNumber
                if let value = item.adjustedAverage {
                    point.y = value as NSNumber
                } else {
                    point.y = 0
                }
                
                chartData.append(point)
            }
            
            // setup scale bar data
            if let connectionRaw = snapshot.getTopLevelRawValue(forSummaryItem: .Connection), let connectionLevel = snapshot.getTopLevelRawLevelValue(forSummaryItem: .Connection) {
                let cellInfo = ScalebarCellInfo(type: .Green, title: "Estimated Connection", score: connectionRaw, position: connectionLevel)
                scalebarData.append(cellInfo)
            }
            
            if let firstPersonRaw = snapshot.getTopLevelRawValue(forSummaryItem: .ConnectionFirstPerson), let firstPersonLevel = snapshot.getTopLevelRawLevelValue(forSummaryItem: .ConnectionFirstPerson) {
                let cellInfo = ScalebarCellInfo(type: .BlueCenter, title: "First Person(%)", score: firstPersonRaw, position: firstPersonLevel)
                scalebarData.append(cellInfo)
            }
        
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
            if let connectionRaw = snapshot.getTopLevelRawValue(forSummaryItem: .ToneOfWords), let connectionLevel = snapshot.getTopLevelRawLevelValue(forSummaryItem: .ToneOfWords) {
                let cellInfo = ScalebarCellInfo(type: .Green, title: "Estimated Emotional Connection", score: connectionRaw, position: connectionLevel)
                scalebarData.append(cellInfo)
            }
            
            if let positiveRaw = snapshot.getTopLevelRawValue(forSummaryItem: .PositiveWords), let positiveLevel = snapshot.getTopLevelRawLevelValue(forSummaryItem: .PositiveWords) {
                let cellInfo = ScalebarCellInfo(type: .BlueRight, title: "Positive Word(%)", score: positiveRaw, position: positiveLevel)
                scalebarData.append(cellInfo)
            }
            
            if let negativeRaw = snapshot.getTopLevelRawValue(forSummaryItem: .NegativeWords), let negativeLevel = snapshot.getTopLevelRawLevelValue(forSummaryItem: .NegativeWords) {
                let cellInfo = ScalebarCellInfo(type: .BlueCenter, title: "Negative Word(%)", score: negativeRaw, position: negativeLevel)
                scalebarData.append(cellInfo)
            }
            
            // setup transcript data
            for (index, item) in toneTable.enumerated() {
                let text = "[\(index)]: \(item.word) (Score: \(item.score))"
                transcript.append(TranscriptCellInfo(withText: text))
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
        let colorArray = [
            [NSNumber(value: 0), "rgb(0, 128 ,0)"],
            [NSNumber(value: 0.5), "rgba(216,216,216, 0)"],
            [NSNumber(value: 0.7), "rgba(47,216,216,0)"],
            [NSNumber(value: 1), "rgb(255, 0 ,0)"]]
        
        let options = HIOptions()
        let title = HITitle()
        title.reserveSpace = false
        title.text = ""
        
        let chart = HIChart()
        chart.zoomType = "x"
        
        let yaxis = HIYAxis()
        yaxis.title = HITitle()
        yaxis.title.text = ""
        yaxis.title.reserveSpace = false
        yaxis.visible = false
        
        switch chartType! {
        case .WordChoice, .BackAndForth, .Connection:
            yaxis.min = -1.05
            yaxis.max = 1.05
            yaxis.tickInterval = 0.21
        case .Emotions:
            yaxis.min = -0.5
            yaxis.max = 0.5
            yaxis.tickInterval = 0.1
        }
        
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
        
        let events = HIEvents()
        let clickClosure: HIClosure =  { (context: HIChartContext?) in
            print("~>Got click event.")
            if let row = context?.getProperty("this.x") as? Int {
                var shouldScroll = false
                print("~>This location: \(row)")
                var indexPath: IndexPath = IndexPath(row: 0, section: 0)
                switch self.chartType! {
                case .BackAndForth:
                    print("~>Back and forth")
                    // back and forth is the word number
                    if row == 0 {
                        indexPath = IndexPath(row: 0, section: 1)
                        break
                    }
                    var wordCount = 0
                    var shouldContinue = true
                    for (index, transcript) in self.snapshot.transcript.enumerated() {
                        if !shouldContinue { break }
                        let wordsToCount = transcript.words.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
                        for _ in wordsToCount {
                            wordCount += 1
                            if wordCount == row {
                                indexPath = IndexPath(row: index, section: 1)
                                shouldScroll = true
                                shouldContinue = false
                                break
                            }
                        }
                    }
                case .Emotions:
                    print("~>Emotions.")
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
                default:
                    print("~>Default")
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
                    print("~>Not a point")
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
            return scalebarData.count
        default:
            return transcript.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard viewNoSnapshots.isHidden else {
            // just return an empty cell
            return UITableViewCell()
        }
        
        switch indexPath.section {
        case 0:
            // setup scalebar
            let cell = tableView.dequeueReusableCell(withIdentifier: CellID.ScaleBar, for: indexPath) as! ScaleBarTableViewCell
            let info = scalebarData[indexPath.row]
            
            switch indexPath.row {
            case 0:
                cell.scaleBar.labelType = .IntValue
            default:
                cell.scaleBar.labelType = .Percent
            }
            
            cell.scaleBar.setupBar(ofType: info.type, withValue: info.score, andLabelPosition: info.position)
            cell.lblDescription.text = info.title
            
            if chartDidLoad {
                setupPopover(for: cell)
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
        
        if let cell = tableView.cellForRow(at: indexPath) as? TranscriptTableViewCell {
            // remove any old annotations
            chartView.removeAnnotation(byId: "annotation")
            guard chartView.options.series[0].data.count > indexPath.row else { return }
            
            // hide the tooltip if it was showing
//            let options = HIOptions()
//            let toolTip = HITooltip()
//            toolTip.enabled = false
//            options.tooltip = toolTip
//
//            chartView.update(options)
//
            var words = cell.lblTranscriptText.text
            var item: HIPoint = HIPoint()
            
            if chartType! == .Emotions {
                // find the correct data point
                let toneGraph = snapshot.graphTone
                let rawItem = snapshot.tableViewTone[indexPath.row]
                for (index, toneItem) in toneGraph.enumerated() {
                    if toneItem.word == rawItem.word && toneItem.roll3 == rawItem.roll3
                        && toneItem.rollNeg3 == rawItem.rollNeg3 && toneItem.rollPos3 == rawItem.rollPos3 {
                        // item was found, link them and be done
                        item = chartView.options.series[0].data[index] as! HIPoint
                    }
                }
                
                
            } else if chartType! == .BackAndForth {
                var wordCount: Int = 0
                for (index, transcript) in snapshot.transcript.enumerated() {
                    let wordsToCount = transcript.words.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
                    if indexPath.row == index {
                        if wordsToCount.count == 1 {
                            words = wordsToCount.first!
                        } else {
                            words = ""
                            for (index, word) in wordsToCount.enumerated() {
                                words = "\(words!)\(word)"
                                if index == 2 {
                                    words = "\(words!)..."
                                    break
                                } else {
                                    words = "\(words!) "
                                }
                            }
                        }
                        
                        break
                    } else {
                        wordCount += wordsToCount.count
                    }
                    
                }
                
                // prevent crashing in case the index is out of range
                if wordCount >= chartView.options.series[0].data.count { wordCount = chartView.options.series[0].data.count - 1 }
                
                item = chartView.options.series[0].data[wordCount] as! HIPoint
            } else {
                item = chartView.options.series[0].data[indexPath.row] as! HIPoint
            }
            
            let annotations = HIAnnotations()
            annotations.labels = [HILabels]()
            let label = HILabels()
            label.align = "top"
            label.point = HIPoint()
            label.point.xAxis = 0
            label.point.yAxis = 0
            label.point.x = item.x
            label.point.y = item.y
            label.text = words
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
        return 64
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if let cell = tableView.visibleCells.first, let indexPath = tableView.indexPath(for: cell) {
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
        
        scrollCounter = 0
    }
    
    private func getX(for bar: ScaleBar) -> CGFloat {
        let value = CGFloat(bar.calculatedValue)
        return bar.bounds.width * value
    }
    
    private func setupPopover(for cell: ScaleBarTableViewCell) {
        let text = cell.scaleBar.labelText
        let frame = CGRect(x: getX(for: cell.scaleBar), y: cell.scaleBar.frame.origin.y - ((20 - cell.scaleBar.frame.height) / 2), width: 56, height: 20)
        
        if cell.popoverView == nil {
            cell.popoverView = LabelBubbleView(frame: frame, withText: text)
            cell.popoverView.alpha = 0.0
            cell.addSubview(cell.popoverView)
            cell.bringSubviewToFront(cell.popoverView)
            UIView.animate(withDuration: 0.25) {
                cell.popoverView.alpha = 1.0
            }
        } else {
            cell.popoverView.updateLabel(withText: text, frame: frame)
        }
        
        // adjust frame if needed
        if cell.popoverView.frame.maxX >= cell.scaleBar.frame.maxX {
            cell.popoverView.frame.origin.x -= cell.popoverView.frame.maxX - cell.scaleBar.frame.maxX
        }
        
        if cell.popoverView.frame.minX <= cell.scaleBar.frame.minX {
            cell.popoverView.frame.origin.x += cell.scaleBar.frame.minX - cell.popoverView.frame.minX
        }
    }
}
