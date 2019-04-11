//
//  SettingsTableViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 4/11/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

class SettingsTableViewController: UITableViewController {
    
    // IBOutlets
    
    @IBOutlet weak var lblEmail: UILabel!
    @IBOutlet weak var lblCredits: UILabel!
    @IBOutlet weak var lblRenewDate: UILabel!
    @IBOutlet weak var tglPhoneNumber: UISwitch!
    @IBOutlet weak var txtPhone: UITextField!
    
    var appDelegate: AppDelegate!
    var user: CharmUser!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        lblEmail.text = ""
        lblCredits.text = ""
        lblRenewDate.text = ""
        txtPhone.text = ""
        txtPhone.delegate = self
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
            
            self.user = self.appDelegate.user
            
            // setup labels
            self.lblEmail.text = self.user.userProfile.email
            self.lblCredits.text = self.user.userProfile.credits
            self.lblRenewDate.text = self.user.userProfile.renewDateString
            
            // setup phone number toggle
            self.tglPhoneNumber.isOn = self.user.userProfile.phone != nil
            self.txtPhone.isEnabled = self.tglPhoneNumber.isOn
            
            if let phone = self.user.userProfile.phone {
                self.txtPhone.text = phone
            }
            
        }
    }
    
    // MARK: - Button Handling
    
    @IBAction func contactsButtonTapped(_ sender: Any) {
        print("~>Contacts")
    }
    
    @IBAction func logoutButtonTapped(_ sender: Any) {
        print("~>Logout")
    }
    
    @IBAction func phoneNumberToggled(_ sender: Any) {
        guard let sender = sender as? UISwitch else { return }
        txtPhone.isEnabled = sender.isOn
        print("~>Phone number toggled")
    }
    
    @IBAction func submitBugReportTapped(_ sender: Any) {
        print("~>Submit bug report")
    }
    
    @IBAction func termsOfUseTapped(_ sender: Any) {
        print("~>Terms of Use")
    }
    
    @IBAction func privacyPolicyTapped(_ sender: Any) {
        print("~>Privacy Policy")
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
        let ref = Database.database().reference().child(FirebaseStructure.Users)
        let phoneQuery = ref.queryOrdered(byChild: "userProfile/phone").queryEqual(toValue: phone).queryLimited(toFirst: 1)
        phoneQuery.observeSingleEvent(of: .value) { (snapshot) in
            
            if !snapshot.exists() {
                self.handleNotFound()
            }
            
            if let results = snapshot.value as? [AnyHashable:Any], let first = results.first?.value {
                print("~>Phone number found: \(first)")
                do {
                    let charmUser = try FirebaseDecoder().decode(CharmUser.self, from: first)
                    self.handleFound(charmUser)
                } catch let error {
                    print("~>There was an error: \(error)")
                }
                
            }
        }
        
    }
    
    fileprivate func handleFound(_ user: CharmUser) {
        print("~>Found: \(user)")
        // nothing changed, so just return
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
        
        do {
            let profile = try FirebaseEncoder().encode(user.userProfile)
            print("~>Got the profile: \(profile)")
            Database.database().reference().child(FirebaseStructure.Users).child(uid).child(FirebaseStructure.CharmUser.Profile).setValue(profile)
        } catch let error {
            print("~>There was an error trying to encode the phone user profile: \(error)")
            let alert = UIAlertController(title: "Error", message: "An unknown error occurred, please try again later.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
}
