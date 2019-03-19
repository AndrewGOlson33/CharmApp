//
//  TempTestViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 3/19/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit

class TempTestViewController: UIViewController {
    
    @IBOutlet weak var scaleBar: ScaleBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        scaleBar.setupBar(ofType: .BlueCenter, withValue: 7.5)
    }
    

    @IBAction func ohNo(_ sender: Any) {

        /* 2 */
        //Configure the presentation controller
        let popoverContentController = self.storyboard?.instantiateViewController(withIdentifier: StoryboardID.LabelPopover) as? LabelBubbleViewController
        popoverContentController?.modalPresentationStyle = .popover
        popoverContentController?.labelText = "\(scaleBar.value)"
        
        /* 3 */
        if let popoverPresentationController = popoverContentController?.popoverPresentationController {
            popoverPresentationController.permittedArrowDirections = .down
            popoverPresentationController.backgroundColor = #colorLiteral(red: 0.7843906283, green: 0.784409225, blue: 0.7843992114, alpha: 1)
            popoverPresentationController.sourceView = view
            popoverPresentationController.sourceRect = CGRect(x: getX(for: scaleBar), y: scaleBar.frame.minY - 2, width: 0, height: 0)
            popoverPresentationController.delegate = self
            if let popoverController = popoverContentController {
                present(popoverController, animated: true, completion: nil)
            }
        }
    }
    
    private func getX(for bar: ScaleBar) -> CGFloat {
        let value = CGFloat(bar.calculatedValue)
        return bar.bounds.width * value
    }
}

extension TempTestViewController: UIPopoverPresentationControllerDelegate {
    //UIPopoverPresentationControllerDelegate inherits from UIAdaptivePresentationControllerDelegate, we will use this method to define the presentation style for popover presentation controller
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    //UIPopoverPresentationControllerDelegate
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        
    }
    
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        return false
    }
}
