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
    
    @IBOutlet weak var logOutButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        if UserDefaultsHelper.isSignedIn() {
            let button = logOutButton.customView as! UIButton
            button.setTitle("Sign Out", for:.normal)
        } else {
            let button = logOutButton.customView as! UIButton
            button.setTitle("Sign In", for:.normal)
        }
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
    
    @IBAction func logOutButtonPressed(_ sender: Any) {
        
        if UserDefaultsHelper.isSignedIn() { // warn about losing data and prompt if they still want to log out
            let alertController = UIAlertController(title: "Are you sure you want to Sign Out?", message: "Any records stored locally on your device will be removed.  Any changes not yet synced to the cloud will be lost.", preferredStyle: UIAlertControllerStyle.alert) //Replace UIAlertControllerStyle.Alert by UIAlertControllerStyle.alert
            let DestructiveAction = UIAlertAction(title: "Sign Out Anyway", style: UIAlertActionStyle.destructive) {
                (result : UIAlertAction) -> Void in
                print("Sign Out Anyway")
                print("Deleting All Records")
                CoreDataHelper.deleteAll()
                print("Records Deleted, Signed Out")
                
                UserDefaultsHelper.isSignedIn(bool: false)
                
                //go to sign up page
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "AccountQuestionViewController")
                
                self.present(vc, animated: true, completion: nil)
            }
            
            // Replace UIAlertActionStyle.Default by UIAlertActionStyle.default
            let okAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default) {
                (result : UIAlertAction) -> Void in
                print("Cancel")
            }
            
            alertController.addAction(DestructiveAction)
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        } else { // tell user they won't lose data and log in.
            let alertController = UIAlertController(title: "Sign In", message: "Once signed in, any records stored locally on your device will be associated with your account and synced to the cloud.", preferredStyle: UIAlertControllerStyle.alert) //Replace UIAlertControllerStyle.Alert by UIAlertControllerStyle.alert
            let DestructiveAction = UIAlertAction(title: "Sign In", style: UIAlertActionStyle.default) {
                (result : UIAlertAction) -> Void in
                
                UserDefaultsHelper.isSignedIn(bool: false)
                
                //go to sign up page
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "AccountQuestionViewController")
                
                self.present(vc, animated: true, completion: nil)
            }
            
            // Replace UIAlertActionStyle.Default by UIAlertActionStyle.default
            let okAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default) {
                (result : UIAlertAction) -> Void in
                print("Cancel")
            }
            
            alertController.addAction(DestructiveAction)
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
}
