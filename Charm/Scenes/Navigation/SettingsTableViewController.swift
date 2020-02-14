//
//  SettingsTableViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 4/11/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit
import Firebase

enum DocumentType {
    case PrivacyPolicy
    case TermsOfUse
}

class SettingsTableViewController: UITableViewController {
    
    // IBOutlets
    
    @IBOutlet weak var txtName: UITextField!
    @IBOutlet weak var lblEmail: UILabel!
    @IBOutlet weak var lblCredits: UILabel!
    @IBOutlet weak var lblRenewDate: UILabel!
    @IBOutlet weak var tglPhoneNumber: UISwitch!
    @IBOutlet weak var txtPhone: UITextField!
    @IBOutlet weak var lblSubscription: UILabel!
    
    var appDelegate: AppDelegate!
    var user: CharmUser!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        lblEmail.text = ""
        lblCredits.text = ""
        lblRenewDate.text = ""
        txtPhone.text = ""
        txtName.text = ""
        txtPhone.delegate = self
        txtName.delegate = self
        txtPhone.isEnabled = false
        
        // setup done button
        let numberToolbar = UIToolbar(frame:CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        numberToolbar.barStyle = .default
        numberToolbar.items = [
            UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(keyboardCancelTapped(_:))),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(keyboardSaveTapped(_:)))]
        numberToolbar.sizeToFit()
        txtPhone.inputAccessoryView = numberToolbar
        
        DispatchQueue.main.async {
            self.appDelegate = UIApplication.shared.delegate as? AppDelegate
            
            guard self.appDelegate != nil else {
                self.navigationController?.popViewController(animated: true)
                return
            }
            
            self.updateLabels()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(updateLabels), name: FirebaseNotification.CharmUserDidUpdate, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: FirebaseNotification.CharmUserDidUpdate, object: nil)
    }
    
    @objc private func updateLabels() {
        user = FirebaseModel.shared.charmUser
        
        // setup labels
        lblEmail.text = user.userProfile.email
        lblCredits.text = user.userProfile.credits
        txtName.text = user.userProfile.firstName + " " + user.userProfile.lastName
        
        // setup subscription labels and add credits if needed
        if let current = SubscriptionService.shared.currentSubscription, current.isActive {
            lblSubscription.text = current.level.rawValue
            lblRenewDate.text = user.userProfile.renewDateString
        } else {
            lblSubscription.text = "Not Subscribed"
            lblRenewDate.text = "N/A"
        }
        
        // setup phone number toggle
        tglPhoneNumber.isOn = user.userProfile.phone != ""
        txtPhone.isEnabled = tglPhoneNumber.isOn
        
        if !self.user.userProfile.phone.isEmpty {
            self.txtPhone.text = self.user.userProfile.phone
        }
    }
    
    // MARK: - Button Handling
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cid = tableView.cellForRow(at: indexPath)?.reuseIdentifier else {
            tableView.deselectRow(at: indexPath, animated: false)
            return
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch cid {
        case CellID.friendList:
            performSegue(withIdentifier: SegueID.friendList, sender: self)
        case CellID.subscriptionsList:
            performSegue(withIdentifier: SegueID.subscriptions, sender: self)
        case CellID.feedback:
            performSegue(withIdentifier: SegueID.submitFeedback, sender: self)
        case CellID.logOut:
            logoutButtonTapped()
        case CellID.termsOfUse:
            performSegue(withIdentifier: SegueID.showInfo, sender: DocumentType.TermsOfUse)
        case CellID.privacyPolicy:
            performSegue(withIdentifier: SegueID.showInfo, sender: DocumentType.PrivacyPolicy)
        default:
            print("~>Not handled")
        }
    }
    
    @IBAction func phoneNumberToggled(_ sender: Any) {
        guard let sender = sender as? UISwitch else { return }
        txtPhone.isEnabled = sender.isOn
    }
    
    // MARK: - Private Helper Functions
    
    private func showLoginScreen() {
        DispatchQueue.main.async {
            let login = self.storyboard?.instantiateViewController(withIdentifier: StoryboardID.login)
            let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
            // clear out any calls as needed
            appDelegate.window?.rootViewController = login
            appDelegate.window?.makeKeyAndVisible()
        }
    }
    
    private func logoutButtonTapped() {
        print("~>Logout")
        let logoutAlert = UIAlertController(title: "Confirm Logout", message: "Are you sure you want to log out?", preferredStyle: .alert)
        logoutAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        logoutAlert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { (_) in
            do {
                try Auth.auth().signOut()
                self.showLoginScreen()
            } catch let error {
                print("~>There was an error logging out: \(error)")
                let logoutError = UIAlertController(title: "Error", message: "There was an error logging out, please try again later.", preferredStyle: .alert)
                logoutAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(logoutError, animated: true, completion: nil)
            }
        }))
        
        present(logoutAlert, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueID.showInfo, let infoVC = segue.destination as? InfoModuleViewController, let type = sender as? DocumentType {
            infoVC.documentType = type
        }
    }
}

extension SettingsTableViewController: UITextFieldDelegate {
    
    // MARK: - Keyboard Toolbar Button Handling
    
    @objc fileprivate func keyboardCancelTapped(_ sender: Any) {
        txtPhone.resignFirstResponder()
    }
    
    @objc fileprivate func keyboardSaveTapped(_ sender: Any) {
        txtPhone.resignFirstResponder()
        
        // make sure we have a number
        guard let phone = txtPhone.text else { return }
        
        // save number to firebase
        let ref = Database.database().reference().child(FirebaseStructure.usersLocation)
        let phoneQuery = ref.queryOrdered(byChild: "userProfile/phone").queryEqual(toValue: phone).queryLimited(toFirst: 1)
        phoneQuery.observeSingleEvent(of: .value) { (snapshot) in
            
            if !snapshot.exists() {
                self.handleNotFound()
            }
            
            if let first = snapshot.children.first(where: { (_) -> Bool in
                return true
            }) as? DataSnapshot {
                do {
                    let charmUser = try CharmUser(snapshot: first)
                    self.handleFound(charmUser)
                } catch let error {
                    print("~>There was an error: \(error)")
                }
                
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard textField == txtName, let text = txtName.text else {
            textField.resignFirstResponder()
            return false
        }
        
        textField.resignFirstResponder()
        
        user.userProfile.updateUser(name: text)
        
        return false
    }
    
    fileprivate func handleFound(_ user: CharmUser) {
        if user.id == self.user.id { return }
        
        // let the user know that someone is already using this number
        let alert = UIAlertController(title: "Phone Number in Use", message: "This phone number is already associated with another user's account.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    fileprivate func handleNotFound() {
        guard let phone = txtPhone.text, let uid = user.id else { return }
        
        guard phone.isPhoneNumber else {
            let alert = UIAlertController(title: "Invalid", message: "Please enter a valid phone number.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        
        user.userProfile.phone = phone
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            Database.database().reference().child(FirebaseStructure.usersLocation).child(uid).child(FirebaseStructure.CharmUser.profileLocation).setValue(self.user.userProfile.toAny())
        }
    }
}
