//
//  SessionSummaryViewController.swift
//  Charm
//
//  Created by Mobile Master on 7/18/20.
//  Copyright © 2020 Charm, LLC. All rights reserved.
//

import UIKit

class SessionSummaryViewController: UIViewController {
    @IBOutlet weak var wordProgress: UIProgressView!
    @IBOutlet weak var specificProgress: UIProgressView!
    @IBOutlet weak var personalProgress: UIProgressView!
    @IBOutlet weak var emotionProgress: UIProgressView!
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var specificLabel: UILabel!
    @IBOutlet weak var personalLabel: UILabel!
    @IBOutlet weak var emotionLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    var trainingModel = TrainingIntensityViewModel()
    override func viewDidLoad() {
        super.viewDidLoad()

        wordProgress.progress = trainingModel.wordScore.score
        specificProgress.progress = trainingModel.specificScore.score
        personalProgress.progress = trainingModel.personalScore.score
        emotionProgress.progress = trainingModel.emotionScore.score
        
        wordLabel.text = trainingModel.wordScore.label
        specificLabel.text = trainingModel.specificScore.label
        personalLabel.text = trainingModel.personalScore.label
        emotionLabel.text = trainingModel.emotionScore.label
        
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    @IBAction func closeButtonClicked(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
    }
}

extension SessionSummaryViewController: UITableViewDataSource, UITableViewDelegate {
    func heightForView(text: String, font:UIFont, width:CGFloat) -> CGFloat {
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: .greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = font
        label.text = text
        
        label.sizeToFit()
        return label.frame.height
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        trainingModel.phrases.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 14)
        guard trainingModel.phrases.count > indexPath.row else { return 44 }
        let text = trainingModel.phrases[indexPath.row].text
        let height = heightForView(text: text ?? "", font: font, width: tableView.frame.width * 0.75)
        let difference = height - 17
        return difference > 0 ? 44 + difference : 44
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellID.transcript, for: indexPath) as! TranscriptTableViewCell

        let info = trainingModel.phrases[indexPath.row]
        cell.setup(withPhrase: info)

        return cell
    }
}
