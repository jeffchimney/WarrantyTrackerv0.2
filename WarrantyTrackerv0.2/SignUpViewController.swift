//
//  SignUpViewController.swift
//  WarrantyTrackerv0.2
//
//  Created by Jeff Chimney on 2017-01-05.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit
import CloudKit
import CoreData

class SignUpViewController: UIViewController {
    
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    
    var signingIn: Bool!
    var timesSignUpPressed = 0
    var timesSignInPressed = 0
    
    override func viewDidLoad() {
        
        if signingIn! {
            signInButton.setTitle("Sign In", for: .normal)
        } else {
            signInButton.setTitle("Sign Up", for: .normal)
        }
    }
    
    @IBAction func signUpButtonPressed(_ sender: Any) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        if !signingIn! { // create new username password combo and save to cloud and locally
            let managedContext = appDelegate.persistentContainer.viewContext
        
            let accountEntity = NSEntityDescription.entity(forEntityName: "Account", in: managedContext)!
        
            let account = NSManagedObject(entity: accountEntity, insertInto: managedContext) as! Account
        
            let publicDatabase:CKDatabase = CKContainer.default().publicCloudDatabase
        
            let accountRecord = CKRecord(recordType: "Accounts")
        
            accountRecord.setValue(usernameField.text, forKey: "username")
            accountRecord.setValue(passwordField.text, forKey: "password")
        
            // save to the cloud
            publicDatabase.save(accountRecord, completionHandler: { (record, error) in
                if error != nil {
                    print("There was an error saving to cloudkit!")
                } else {
                    account.username = self.usernameField.text
                    account.password = self.passwordField.text
                    account.id = accountRecord.recordID.recordName
                }
            })
        
            // save locally
            do {
                try managedContext.save()
            } catch {
                print("Could not save account info.")
            }
            
            // set userdefaults for first launch
            let defaults = UserDefaults.standard
            defaults.set(false, forKey: "FirstLaunch")
            
            // navigate to primary controller
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "baseNavController")
            
            self.present(vc, animated: true, completion: nil)
        } else { // fetch existing username/password combo and save locally
            let managedContext = appDelegate.persistentContainer.viewContext
            
            let accountEntity = NSEntityDescription.entity(forEntityName: "Account", in: managedContext)!
            
            let account = NSManagedObject(entity: accountEntity, insertInto: managedContext) as! Account
            
            let publicDatabase:CKDatabase = CKContainer.default().publicCloudDatabase
            
            account.username = self.usernameField.text
            account.password = self.passwordField.text
            //account.id = accountRecord.recordID.recordName        set when record has been retrieved
            
            // save locally
            do {
                try managedContext.save()
            } catch {
                print("Could not save account info.")
            }
            
            // set userdefaults for first launch
            let defaults = UserDefaults.standard
            defaults.set(false, forKey: "FirstLaunch")
            
            // navigate to primary controller
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "baseNavController")
            
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    // check changes in text fields to see if already exists
    func checkIfUsernameExists(username: String) {
        
    }
}
