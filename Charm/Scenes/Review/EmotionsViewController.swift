//
//  EmotionsViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 3/19/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit

class EmotionsViewController: UIViewController {

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == SegueID.detailChart, let chartVC = segue.destination as? DetailChartViewController else { return }
        chartVC.chartType = .emotions
        chartVC.navTitle = "Emotional Journey"
    }

}
