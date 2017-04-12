//
//  SettingsTableViewController.swift
//  WarrantyTrackerv0.2
//
//  Created by Jeff Chimney on 2017-02-19.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit
import CloudKit
import CoreData

class SettingsTableViewController: UITableViewController {
    
    @IBOutlet weak var usernameCell: UITableViewCell!
    
    override func viewDidLoad() {
        
    }
    
    override func viewDidLayoutSubviews() {
        let defaults = UserDefaults.standard
        let username = defaults.string(forKey: "username")
        
        if username != nil { // user is logged in
            
        }
        
        let usernameRow = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as! UsernamePasswordTableViewCell
        
        if UserDefaultsHelper.isSignedIn() {
            usernameRow.usernameLabel.text = UserDefaultsHelper.getUsername()
        } else {
            usernameRow.usernameLabel.text = "N/A"
        }
        
        let toggleRow = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as! TitleAndSwitchTableViewCell
        toggleRow.toggle.isOn = UserDefaultsHelper.canSyncUsingData()
    }
}
