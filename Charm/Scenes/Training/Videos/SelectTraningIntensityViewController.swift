//
//  SelectTraningIntensityViewController.swift
//  Charm
//
//  Created by Mobile Master on 7/15/20.
//  Copyright © 2020 Charm, LLC. All rights reserved.
//

import UIKit

enum TrainingIntensity: Int {
    case casual, regular, serious, freeform
    
    var title: String {
        switch self {
        case .casual:
            return "Casual"
        case .regular:
            return "Regular"
        case .serious:
            return "Serious"
        case .freeform:
            return "Freeform"
        }
    }
    
    var blanks: Int {
        switch self {
        case .casual:
            return 3
        case .regular:
            return 2
        case .serious:
            return 1
        case .freeform:
            return -1
        }
    }
    
    static var count: Int { return TrainingIntensity.freeform.rawValue + 1 }
    static var seconds: Int { return 10 * 60 }
}

class SelectTraningIntensityViewController: UIViewController {
    @IBOutlet weak var descriptionView: UIView!
    @IBOutlet weak var tableBackgroundView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var progressBar: UIProgressView!
    
    var partner: PracticePartner!
    private var selectedTrainingIntensity: TrainingIntensity = .regular
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    private func setupUI() {
        descriptionView.isHidden = UserDefaults.standard.bool(forKey: Defaults.neverShowPracticeDescription)

        tableBackgroundView.layer.borderWidth = 2
        tableBackgroundView.layer.borderColor = UIColor(hex: "EDEDED").cgColor
        tableBackgroundView.layer.cornerRadius = 20
        
        progressBar.progress = Float(ConversationManager.shared.progress)
    }
    
    @IBAction func nextButtonClicked(_ sender: Any) {
        descriptionView.isHidden = true
    }
    
    @IBAction func neverShowButtonClicked(_ sender: Any) {
        descriptionView.isHidden = true
        UserDefaults.standard.set(true, forKey: Defaults.neverShowPracticeDescription)
    }
    
    @IBAction func backButtonClicked(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func startButtonClicked(_ sender: Any) {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "PracticeVideoViewController") as? PracticeVideoViewController else { return }
        vc.partner = partner
        vc.currentTrainingIntensity = selectedTrainingIntensity
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension SelectTraningIntensityViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return TrainingIntensity.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.tableBackgroundView.frame.height / CGFloat(TrainingIntensity.count)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TrainingIntensityCell", for: indexPath) as! TrainingIntensityCell
        let trainingIntensity = TrainingIntensity(rawValue: indexPath.row)
        cell.titleLabel.text = trainingIntensity?.title
        cell.setMarked(selectedTrainingIntensity == trainingIntensity)
        cell.bottomLineView.isHidden = trainingIntensity == .freeform
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedTrainingIntensity = TrainingIntensity(rawValue: indexPath.row) ?? .regular
        self.tableView.reloadData()
    }
}
