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
    
    
    // MARK: - Properties
    
    // data chart will be built with
    var snapshot: Snapshot!
    var cellInfo: [SummaryCellInfo] = []
    
    // calculated averages
    var mindAverage: Double = 0.0
    var heartAverage: Double = 0.0
    
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            
        }
        
        if #available(iOS 13.0, *) {
                let navBarAppearance = UINavigationBarAppearance()
                navBarAppearance.configureWithOpaqueBackground()
                navBarAppearance.accessibilityTextualContext = .sourceCode
                navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
                navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
                navBarAppearance.backgroundColor = #colorLiteral(red: 0, green: 0.1725181639, blue: 0.3249038756, alpha: 1)

                self.navigationController?.navigationBar.standardAppearance = navBarAppearance
                self.navigationController?.navigationBar.compactAppearance = navBarAppearance
                self.navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        }
        
        setupSnapshotData()
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeSnapshotObserver()
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
        let ideaEngagement = snapshot.getTopLevelScoreValue(forSummaryItem: .ideaEngagement) ?? 0
        let conversationEngagement = snapshot.getTopLevelScoreValue(forSummaryItem: .conversationEngagement) ?? 0
        let personalConnection = snapshot.getTopLevelScoreValue(forSummaryItem: .personalConnection) ?? 0
        let emotionalConnection = snapshot.getTopLevelScoreValue(forSummaryItem: .emotionalConnection) ?? 0
        let smiling = snapshot.getTopLevelScoreValue(forSummaryItem: .smilingPercentage) ?? 0
        
        // get scores for cell info
        let ideaPercent = snapshot.getTopLevelRawValue(forSummaryItem: .ideaEngagement) ?? 0
        let conversationPercent = snapshot.getTopLevelRawValue(forSummaryItem: .conversationEngagement) ?? 0
        let personalConnectionPercent = snapshot.getTopLevelRawValue(forSummaryItem: .personalConnection) ?? 0
        let emotionalConnectionPercent = snapshot.getTopLevelRawValue(forSummaryItem: .emotionalConnection) ?? 0
        let smilingPercent = snapshot.getTopLevelRawValue(forSummaryItem: .smilingPercentage) ?? 0

        // setup cell info array
        cellInfo.append(SummaryCellInfo(title: "Word Engagement", score: ideaEngagement, percent: ideaPercent))
        cellInfo.append(SummaryCellInfo(title: "Conversation Engagement", score: conversationEngagement, percent: conversationPercent))
        cellInfo.append(SummaryCellInfo(title: "Personal Connection", score: personalConnection, percent: personalConnectionPercent))
        cellInfo.append(SummaryCellInfo(title: "Emotional Connection", score: emotionalConnection, percent: emotionalConnectionPercent))
        cellInfo.append(SummaryCellInfo(title: "Smiling", score: smiling, percent: smilingPercent))
        
        // load averages
        mindAverage = (ideaEngagement + conversationEngagement) / 2.0
        heartAverage = (personalConnection + emotionalConnection + smiling) / 3.0
    }
    
    private func setupScoreUI() {
        guard let snapshot = self.snapshot else { return }
        let dateString = snapshot.friendlyDateString.isEmpty ? "" : "\n" + snapshot.friendlyDateString
        lblSummaryTitle.text = "Your conversation with \(snapshot.friend)\(dateString)"
        
        for info in cellInfo {
            switch info.title {
            case "Word Engagement":
                lblWordEngScore.text = info.scoreString
                wordEngSlider.setup(for: .fillFromLeft, at: CGFloat(info.percent))
            case "Conversation Engagement":
                lblConvoEngScore.text = info.scoreString
                convoEngSlider.setup(for: .fillFromLeft, at: CGFloat(info.percent))
            case "Personal Connection":
                lblPersonalConScore.text = info.scoreString
                personalConSlider.setup(for: .fillFromLeft, at: CGFloat(info.percent))
            case "Emotional Connection":
                lblEmoConScore.text = info.scoreString
                emoConSlider.setup(for: .fillFromLeft, at: CGFloat(info.percent))
            case "Smiling":
                lblSmilingScore.text = info.scoreString
                smilingSlider.setup(for: .fillFromLeft, at: CGFloat(info.percent))
            default:
                return
            }
        }
    }
    
    private func setupCharts() {
        setup(chartView: mindChart, withScore: mindAverage, andColor: #colorLiteral(red: 0.4862745098, green: 0.7098039216, blue: 0.9254901961, alpha: 1))
        setup(chartView: heartChart, withScore: heartAverage, andColor: #colorLiteral(red: 0.4941176471, green: 0, blue: 0, alpha: 1))
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
    
    private func loadJSONSnapshotData() {
        print("load json snapshot data")
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
    
    fileprivate func removeSnapshotObserver() {
        NotificationCenter.default.removeObserver(self, name: FirebaseNotification.SnapshotLoaded, object: nil)
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

// MARK: - Extension to double to enable squaring

extension Double {
    
    func value() -> Double {
        return pow(2.71828, self)
    }
    
}

extension Int {
    func value() -> Int {
        let value = pow(2.71828, Double(self))
        return Int(value.rounded())
    }
}
