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
    
    // For displaying data
    
    // charts
    @IBOutlet weak var mindChart: HIChartView!
    @IBOutlet weak var heartChart: HIChartView!
    
    // title label
    @IBOutlet weak var lblSummaryTitle: UILabel!
    @IBOutlet weak var lblSummaryTimestamp: UILabel!
    
    // score labels
    @IBOutlet weak var lblWordEngScore: UILabel!
    @IBOutlet weak var lblConvoEngScore: UILabel!
    @IBOutlet weak var lblPersonalConScore: UILabel!
    @IBOutlet weak var lblEmoConScore: UILabel!
    @IBOutlet weak var lblSmilingScore: UILabel!
    
    // Slider Views
    @IBOutlet weak var wordEngSlider: SliderView!
    @IBOutlet weak var convoEngSlider: SliderView!
    @IBOutlet weak var personalConSlider: SliderView!
    @IBOutlet weak var emoConSlider: SliderView!
    @IBOutlet weak var smilingSlider: SliderView!
    
    // for button handling
    @IBOutlet weak var viewWordEng: UIView!
    @IBOutlet weak var viewConvoEng: UIView!
    @IBOutlet weak var viewPerCon: UIView!
    @IBOutlet weak var viewEmoCon: UIView!
    @IBOutlet weak var viewSmiling: UIView!
    
    // buttons
    @IBOutlet weak var btnHistory: UIButton!
    
    // image views
    
    @IBOutlet weak var imgHeart: UIImageView!
    @IBOutlet weak var imgMind: UIImageView!
    
    // MARK: - Properties
    
    // data chart will be built with
    var snapshot: Snapshot! = FirebaseModel.shared.selectedSnapshot
    var cellInfo: [SummaryCellInfo] = []
    
    // calculated averages
    var mindAverage: Double = 0.0
    var heartAverage: Double = 0.0
    
    // MARK: - View Lifecycle Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // round corners of connecting view
        viewLoading.layer.cornerRadius = 20
        viewLoading.layer.shadowColor = UIColor.black.cgColor
        viewLoading.layer.shadowRadius = 8
        viewLoading.layer.shadowOpacity = 0.6
        viewLoading.layer.shadowOffset = CGSize(width: 2, height: 2)
        
        // set image tint
        imgHeart.image = imgHeart.image?.withRenderingMode(.alwaysTemplate)
        imgMind.image = imgMind.image?.withRenderingMode(.alwaysTemplate)
        if #available(iOS 13.0, *) {
            imgMind.tintColor = .label
            imgHeart.tintColor = .label
        } else {
            imgMind.tintColor = .black
            imgHeart.tintColor = .black
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.navigationItem.title = "Summary"
        
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupSnapshotData()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if #available(iOS 12.0, *) {
            if traitCollection.userInterfaceStyle == .dark {
                mindChart.options.yAxis.first?.title.style.color = "#FFFFFF"
                heartChart.options.yAxis.first?.title.style.color = "#FFFFFF"
            } else {
                mindChart.options.yAxis.first?.title.style.color = "#000000"
                heartChart.options.yAxis.first?.title.style.color = "#000000"
            }
        }
    }
    
    // MARK: - Private Helper Functions
    
    private func setupSnapshotData() {
        // if snapshots are still loading, show the loading view
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
        
        // hide the loading view if it is showing
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
            guard let data = FirebaseModel.shared.snapshots.first else {
                
                // setup example
                loadJSONSnapshotData()
                setupSnapshotData()
                
                return
            }
            
            // Set data
            snapshot = data
            FirebaseModel.shared.selectedSnapshot = snapshot
        } else if let selected = FirebaseModel.shared.selectedSnapshot {
            snapshot = selected
        } else {
            if let first = FirebaseModel.shared.snapshots.first, let shared = FirebaseModel.shared.selectedSnapshot, first.date != shared.date {
                FirebaseModel.shared.selectedSnapshot = first
            } else if let first = FirebaseModel.shared.snapshots.first, FirebaseModel.shared.selectedSnapshot == nil {
                FirebaseModel.shared.selectedSnapshot = first
            }
            
            snapshot = FirebaseModel.shared.selectedSnapshot
        }
        
        // do button setup
        setupButtons()
        
        // setup scores and charts
        loadScoreData()
        setupScoreUI()
        setupCharts()
    }
    
    private func setupButtons() {
        if FirebaseModel.shared.snapshots.count > 1 { btnHistory.isHidden = false }
        
        // setup tap gesture recognizers
        let wordTap = UITapGestureRecognizer(target: self, action: #selector(handle(_:)))
        wordTap.numberOfTouchesRequired = 1
        viewWordEng.addGestureRecognizer(wordTap)
        
        let convoTap = UITapGestureRecognizer(target: self, action: #selector(handle(_:)))
        convoTap.numberOfTouchesRequired = 1
        viewConvoEng.addGestureRecognizer(convoTap)
        
        let perConTap = UITapGestureRecognizer(target: self, action: #selector(handle(_:)))
        perConTap.numberOfTouchesRequired = 1
        viewPerCon.addGestureRecognizer(perConTap)
        
        let emoConTap = UITapGestureRecognizer(target: self, action: #selector(handle(_:)))
        emoConTap.numberOfTouchesRequired = 1
        viewEmoCon.addGestureRecognizer(emoConTap)
    }
    
    private func loadScoreData() {
        // get values for line chart
        
        let ideaEngagement = getSummaryValues(from: snapshot.getTopLevelScoreValue(forSummaryItem: .ideaEngagement) ?? 0)
        let conversationEngagement = getSummaryValues(from: snapshot.getTopLevelScoreValue(forSummaryItem: .conversationEngagement) ?? 0)
        let personalConnection = getSummaryValues(from: snapshot.getTopLevelScoreValue(forSummaryItem: .personalConnection) ?? 0)
        let emotionalConnection = getSummaryValues(from: snapshot.getTopLevelScoreValue(forSummaryItem: .emotionalConnection) ?? 0)
        let smiling = getSummaryValues(from: snapshot.getTopLevelScoreValue(forSummaryItem: .smilingPercentage) ?? 0)
        
        // setup cell info array
        cellInfo.append(SummaryCellInfo(title: "Idea Clarity", score: ideaEngagement.score, percent: ideaEngagement.percent))
        cellInfo.append(SummaryCellInfo(title: "Conversation Flow", score: conversationEngagement.score, percent: conversationEngagement.percent))
        cellInfo.append(SummaryCellInfo(title: "Personal Bond", score: personalConnection.score, percent: personalConnection.percent))
        cellInfo.append(SummaryCellInfo(title: "Emotional Journey", score: emotionalConnection.score, percent: emotionalConnection.percent))
        cellInfo.append(SummaryCellInfo(title: "Smiling", score: smiling.score, percent: smiling.percent))
        
        // load averages
        mindAverage = (ideaEngagement.rawValue + conversationEngagement.rawValue + max(ideaEngagement.rawValue, conversationEngagement.rawValue)) / 3.0
        let heartMax = max(personalConnection.rawValue, emotionalConnection.rawValue, smiling.rawValue) * 2
        heartAverage = (personalConnection.rawValue + emotionalConnection.rawValue + smiling.rawValue + heartMax) / 5.0
    }
    
    fileprivate func getSummaryValues(from value: Double) -> (score: Double, percent: Double, rawValue: Double) {
        return (score: value / 10, percent: value / 10, rawValue: value)
    }
    
    private func setupScoreUI() {
        guard let snapshot = self.snapshot else { return }
        let dateString = snapshot.friendlyDateString.isEmpty ? "" : "On " + snapshot.friendlyDateString
        lblSummaryTitle.text = "Your conversation with \(snapshot.friend)"
        lblSummaryTimestamp.text = dateString
        
        for info in cellInfo {
            switch info.title {
            case "Idea Clarity":
                lblWordEngScore.text = info.scoreString
                wordEngSlider.setup(for: .standard, atPosition: CGFloat(info.percent), color: #colorLiteral(red: 0.4862745098, green: 0.7098039216, blue: 0.9254901961, alpha: 1))
            case "Conversation Flow":
                lblConvoEngScore.text = info.scoreString
                convoEngSlider.setup(for: .standard, atPosition: CGFloat(info.percent), color: #colorLiteral(red: 0.4862745098, green: 0.7098039216, blue: 0.9254901961, alpha: 1))
            case "Personal Bond":
                lblPersonalConScore.text = info.scoreString
                personalConSlider.setup(for: .standard, atPosition: CGFloat(info.percent), color: #colorLiteral(red: 0.8509803922, green: 0.3490196078, blue: 0.3490196078, alpha: 1))
            case "Emotional Journey":
                lblEmoConScore.text = info.scoreString
                emoConSlider.setup(for: .standard, atPosition: CGFloat(info.percent), color: #colorLiteral(red: 0.8509803922, green: 0.3490196078, blue: 0.3490196078, alpha: 1))
            case "Smiling":
                lblSmilingScore.text = info.scoreString
                smilingSlider.setup(for: .standard, atPosition: CGFloat(info.percent), color: #colorLiteral(red: 0.8509803922, green: 0.3490196078, blue: 0.3490196078, alpha: 1))
            default:
                return
            }
        }
    }
    
    private func setupCharts() {
        setup(chartView: mindChart, withScore: mindAverage, andColor: #colorLiteral(red: 0.4862745098, green: 0.7098039216, blue: 0.9254901961, alpha: 1))
        setup(chartView: heartChart, withScore: heartAverage, andColor: #colorLiteral(red: 0.8509803922, green: 0.3490196078, blue: 0.3490196078, alpha: 1))
    }
    
    private func setup(chartView: HIChartView, withScore score: Double, andColor color: UIColor) {
        guard snapshot != nil else { return }
        
        // Initialize Chart Options
        let options = HIOptions()
        
        // tooltip
        let tooltip = HITooltip()
        tooltip.enabled = false
        
        // Setup Chart
        let chart = HIChart()
        chart.type = "solidgauge"
        chart.backgroundColor = HIColor(uiColor: .clear)
        
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
        paneBackground.outerRadius = "118%"
        paneBackground.innerRadius = "88%"
        paneBackground.borderWidth = 0
        let bgColor = color.withAlphaComponent(0.35)
        let backgroundColor = HIColor(uiColor: bgColor)
        
        paneBackground.backgroundColor = backgroundColor
        
        pane.background = [paneBackground]
        
        // score as percent
        let percent = (score / 10 * 100)
        
        // y axis
        
        let yAxis = HIYAxis()
        let yTitle = HITitle()
        yTitle.text = "<center><p><strong style=\"font-size:300%;\">\(Int(percent))</strong><br><small>PERCENT</small></p></center>"
        yTitle.useHTML = true
        yTitle.style = HICSSObject()
        yTitle.style.fontFamily = "Helvetica; sans-serif"
        
        if #available(iOS 12.0, *) {
            if traitCollection.userInterfaceStyle == .dark {
                yTitle.style.color = "#FFFFFF"
            } else {
                yTitle.style.color = "#000000"
            }
        } else {
            yTitle.style.color = "#000000"
        }

        let center = -(chartView.bounds.height / 16)
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
        let labelsOptions = HIDataLabels()//HIDataLabelsOptionsObject()
        labelsOptions.enabled = false
        plotOptions.solidgauge.dataLabels = [labelsOptions]
        plotOptions.solidgauge.linecap = "round"
        plotOptions.solidgauge.stickyTracking = false
        plotOptions.solidgauge.rounded = true
        
        let gage = HISolidgauge()
        gage.name = ""
        let data = HIData()
        data.color = HIColor(uiColor: color)
        data.radius = "118%"
        data.innerRadius = "88%"
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
    
    private func loadJSONSnapshotData() {
        print("load json snapshot data")
        viewEffect.isHidden = false
        let noSnapshotsAlert = UIAlertController(title: "Explore Sample Snapshot", message: "Here you can view your conversation metrics.\n\nYour metrics are scored by our servers, and are based on the speaking styles of the world's most charming people.\n\nYou can generate metrics by calling a friend.  It takes our servers about 15 minutes to process your metrics after your call has completed.", preferredStyle: .alert)
        noSnapshotsAlert.addAction(UIAlertAction(title: "View Sample Snapshot", style: .default, handler:{ (_) in
            self.viewEffect.isHidden = true
        }))

        present(noSnapshotsAlert, animated: true, completion: nil)
        
        guard let path = Bundle.main.path(forResource: "snapshotData", ofType: "json") else { fatalError("~>Unable to find default JSON file.") }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
            let snapshotData = try JSONDecoder().decode(Snapshot.self, from: data)
            self.snapshot = snapshotData
            FirebaseModel.shared.selectedSnapshot = snapshot
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
        
        setupSnapshotData()
    }
    
        
    // MARK: - Handle Button Actions
    
    @objc private func handle(_ tap: UITapGestureRecognizer) {
        guard let view = tap.view else { return }
        tabBarController?.selectedIndex = view.tag
    }
    
    @IBAction func showHistoryProgress(_ sender: Any) {
        performSegue(withIdentifier: SegueID.snapshotsList, sender: self)
    }
}
