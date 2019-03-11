//
//  FriendListTableViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 3/7/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase
import Contacts

class FriendListTableViewController: UITableViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var btnContacts: UIBarButtonItem!
    @IBOutlet weak var btnAddContact: UIBarButtonItem!
    
    // MARK: - Properties
    
    // Search controller
    let searchController = UISearchController(searchResultsController: nil)
    
    // User object that holds friend list
    let viewModel = ContactsViewModel()
    
    // toggle for display contacts or add contacts views
    var isContactsViewShowing: Bool = true
    
    // MARK: - View Lifecycle Functions

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // disable contacts button on launch
        btnContacts.isEnabled = false

        // allow view model to refresh tableview
        viewModel.delegate = self
        
        // setup a search bar
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search your friend list..."
        tableView.tableHeaderView = searchController.searchBar
//        definesPresentationContext = true
        searchController.searchBar.delegate = self
        
    }
    
    // MARK: - Button Handling
    
    @IBAction func contactsButtonTapped(_ sender: Any) {
        btnContacts.isEnabled = false
        btnAddContact.isEnabled = true
        isContactsViewShowing = true
        tableView.reloadData()
    }
    
    @IBAction func addContactButtonTapped(_ sender: Any) {
        btnContacts.isEnabled = true
        btnAddContact.isEnabled = false
        isContactsViewShowing = false
        tableView.reloadData()
    }
    

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if isContactsViewShowing { return "" }
        
        switch section {
        case 0:
            return "Users in My Contacts"
        default:
            return "Add by Phone Number"
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.textColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return isContactsViewShowing ? 3 : 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        switch section {
        case 0:
            return viewModel.currentFriends.count
        case 1:
            return viewModel.pendingReceived.count
        default:
            return viewModel.pendingReceived.count
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: CellID.FriendList, for: indexPath) as! FriendListTableViewCell

        switch indexPath.section {
        case 0:
            cell = viewModel.configureCell(atIndex: indexPath.row, withCell: cell, forType: .Current)
        case 1:
            cell = viewModel.configureCell(atIndex: indexPath.row, withCell: cell, forType: .PendingReceived)
        default:
            cell = viewModel.configureCell(atIndex: indexPath.row, withCell: cell, forType: .PendingSent)
        }
    
        return cell
    }

}

// MARK: - Search Delegate Functions

extension FriendListTableViewController: UISearchResultsUpdating, UISearchBarDelegate {
    
    func updateSearchResults(for searchController: UISearchController) {
//        filterContentForSearchText(searchController.searchBar.text!)
    }
    
    fileprivate func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }
    
    fileprivate func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        searchController.searchBar.resignFirstResponder()
        return true
    }
    
    fileprivate func searchBarIsEmpty() -> Bool {
        // Returns true if the text is empty or nil
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
}

extension FriendListTableViewController: TableViewRefreshDelegate {
    
    func updateTableView() {
        tableView.reloadData()
    }
    
}
