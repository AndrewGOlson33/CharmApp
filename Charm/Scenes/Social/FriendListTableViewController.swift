//
//  FriendListTableViewController.swift
//  Charm
//
//  Created by Daniel Pratt on 3/7/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit
import Firebase
import Contacts

class FriendListTableViewController: UITableViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var btnContacts: UIBarButtonItem!
    @IBOutlet weak var btnAddContact: UIBarButtonItem!
    
    // MARK: - Properties
    
    let activityView = UIActivityIndicatorView()
    
    // Search controller
    let searchController = UISearchController(searchResultsController: nil)
    
    // User object that holds friend list
    let viewModel = ContactsViewModel.shared
    var showContacts: Bool = true
    
    // toggle for display contacts or add contacts views
    var isContactsViewShowing: Bool = true {
        didSet {
            tableView.allowsSelection = isContactsViewShowing ? false : true
        }
    }
    
    // MARK: - View Lifecycle Functions

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.allowsSelection = false
        
        isContactsViewShowing = showContacts
        
        if !showContacts {
            btnContacts.tintColor = .clear
            btnAddContact.tintColor = .clear
            btnContacts.isEnabled = false
            btnAddContact.isEnabled = false
            title = "ADD FRIEND"
        } else {
            // disable contacts button on launch
            btnContacts.isEnabled = false
            title = "CONTACTS"
        }
        
        // allow view model to refresh tableview
        viewModel.delegate = self
        
        // setup a search bar
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search your friend list..."
        tableView.tableHeaderView = searchController.searchBar
        definesPresentationContext = true
        searchController.searchBar.delegate = self
        
        // setup activity view
        
        if #available(iOS 13.0, *) {
            activityView.style = .large
            activityView.color = .label
        } else {
            activityView.style = .whiteLarge
            activityView.color = .black
        }
        
        activityView.hidesWhenStopped = true
        view.addSubview(activityView)
        
        // Position it at the center of the ViewController.
        activityView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityView.centerYAnchor.constraint(equalTo: view.centerYAnchor)])
        
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshContacts), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        showActivity(viewModel.isLoading)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    // MARK: - Button Handling
    
    @IBAction func contactsButtonTapped(_ sender: Any) {
        searchController.resignFirstResponder()
        btnContacts.isEnabled = false
        btnAddContact.isEnabled = true
        isContactsViewShowing = true
        title = "CONTACTS"
        tableView.reloadData()
    }
    
    @IBAction func addContactButtonTapped(_ sender: Any) {
        searchController.resignFirstResponder()
        btnContacts.isEnabled = true
        btnAddContact.isEnabled = false
        isContactsViewShowing = false
        title = "ADD FRIEND"
        tableView.reloadData()
    }
    
    @objc func refreshContacts() {
        viewModel.resetFriendLists()
        tableView.refreshControl?.endRefreshing()
    }
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        switch section {
        case 0:
            return isContactsViewShowing ? isFiltering() ? viewModel.filteredFriends.count == 0 ? "" : "Contacts" : viewModel.currentFriends.count == 0 ? "" : "Contacts" : isFiltering() ? viewModel.filteredPendingReceived.count == 0 ? "" : "Friend Invites" :  viewModel.pendingReceived.count == 0 ? "" : "Friend Invites"
        case 1:
            return isContactsViewShowing ? isFiltering() ? viewModel.filteredPendingSent.count == 0 ? "" : "Pending Friend Approval" : viewModel.pendingSent.count == 0 ? "" : "Pending Friend Approval" : isFiltering() ? viewModel.filteredExistingUsers.count == 0 ? "" : "Users in My Contacts" :  viewModel.existingUsers.count == 0 ? "" : "Users in My Contacts"
        default:
            return isFiltering() ? viewModel.filteredUsersToInvite.count == 0 ? "" : "Add by Phone Number" : viewModel.usersToInvite.count == 0 ? "" : "Add by Phone Number"
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return isContactsViewShowing ? 2 : 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if isContactsViewShowing {
            searchController.searchBar.isHidden = viewModel.currentFriends.count == 0
        }
        
        switch section {
        case 0:
            return isContactsViewShowing ? isFiltering() ? viewModel.filteredFriends.count : viewModel.currentFriends.count > 0 ? viewModel.currentFriends.count : 1 : isFiltering() ? viewModel.filteredPendingReceived.count :  viewModel.pendingReceived.count
        case 1:
            return isContactsViewShowing ? isFiltering() ? viewModel.filteredPendingSent.count : viewModel.pendingSent.count : isFiltering() ? viewModel.filteredExistingUsers.count :  viewModel.existingUsers.count
        default:
            return isFiltering() ? viewModel.filteredUsersToInvite.count : viewModel.usersToInvite.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isContactsViewShowing && viewModel.currentFriends.count == 0 {
            return tableView.dequeueReusableCell(withIdentifier: CellID.emptyChatList)!
        }
        
        var cell = tableView.dequeueReusableCell(withIdentifier: CellID.friendList, for: indexPath) as! FriendListTableViewCell
        
        let filtered = isFiltering()
        
        switch indexPath.section {
        case 0:
            cell = isContactsViewShowing ? viewModel.configureCell(atIndex: indexPath.row, withCell: cell, forType: .Current, filtered: filtered) : viewModel.configureCell(atIndex: indexPath.row, withCell: cell, forType: .PendingReceived, filtered: filtered)
        case 1:
            cell = isContactsViewShowing ? viewModel.configureCell(atIndex: indexPath.row, withCell: cell, forType: .PendingSent, filtered: filtered) : viewModel.configureCell(atIndex: indexPath.row, withCell: cell, forType: .ExistingNotInContacts, filtered: filtered)
        default:
            cell = viewModel.configureCell(atIndex: indexPath.row, withCell: cell, forType: .AddByPhone, filtered: filtered)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let cell = tableView.cellForRow(at: indexPath) as? FriendListTableViewCell else { return }
        if !cell.btnApprove.isHidden { cell.approveButtonTapped(cell.btnApprove!) }
    }
    
    // prevent extra table view lines
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(origin: .zero, size: CGSize(width: tableView.frame.width, height: 1)))
        view.backgroundColor = .clear
        return view
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 81.0
    }
    
    // MARK: - Handle Deleting Friends
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if indexPath.section == 0 { return .delete }

        return .none
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Ask for confirmation before deleting
            let deleteAlert = UIAlertController(title: "Are You Sure?", message: "Are you sure you want to delete this contact?", preferredStyle: .alert)
            deleteAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
            deleteAlert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { (_) in
                // get friend object
                guard let friend = (tableView.cellForRow(at: indexPath) as! FriendListTableViewCell).friend else { return }
                var type: ContactsViewModel.ContactType!
                
                if indexPath.section == 0 && self.isContactsViewShowing {
                    type = .Current
                } else if indexPath.section == 0 {
                    type = .PendingReceived
                } else {
                    return
                }
            
                self.viewModel.delete(friend: friend, fromTableView: self.tableView, atIndexPath: indexPath, ofType: type)
            }))
            present(deleteAlert, animated: true, completion: nil)
        }
    }
}

// MARK: - Search Delegate Functions

extension FriendListTableViewController: UISearchResultsUpdating, UISearchBarDelegate {
    
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.filterSearch(forContacts: isContactsViewShowing, withText: searchController.searchBar.text!)
    }
    
    fileprivate func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }
    
    internal func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
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
    
    func showActivity(_ animating: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if animating && !self.activityView.isAnimating {
                self.activityView.startAnimating()
                self.view.isUserInteractionEnabled = false
            } else if !animating && self.activityView.isAnimating {
                self.activityView.stopAnimating()
                self.view.isUserInteractionEnabled = true
            }
        }
    }
}
