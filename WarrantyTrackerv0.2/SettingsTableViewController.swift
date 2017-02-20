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
    }
}
