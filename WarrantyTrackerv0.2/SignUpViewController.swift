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

class SignUpViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    var signingIn: Bool!
    var timesSignUpPressed = 0
    var timesSignInPressed = 0
    
    override func viewDidLoad() {
        errorLabel.isHidden = true
        indicator.isHidden = true
        
        if signingIn! {
            signInButton.setTitle("Sign In", for: .normal)
        } else {
            signInButton.setTitle("Sign Up", for: .normal)
        }
    }
    
    @IBAction func signUpButtonPressed(_ sender: Any) {
        indicator.isHidden = false
        indicator.startAnimating()
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
            
            let predicate = NSPredicate(format: "username = %@", argumentArray: [usernameField.text!])
            
            let query = CKQuery(recordType: "Accounts", predicate: predicate)
            
            publicDatabase.perform(query, inZoneWith: nil, completionHandler: { (results, error) in
                if error != nil {
                    DispatchQueue.main.async {
                        self.errorLabel.text = "Connection error. Try again later."
                        self.errorLabel.textColor = .red
                        self.errorLabel.isHidden = false
                        self.indicator.isHidden = true
                        self.indicator.stopAnimating()
                    }
                } else {
                    if (results?.count)! > 0 { // username already exists
                        DispatchQueue.main.async {
                            self.errorLabel.text = "That username is already in use."
                            self.errorLabel.textColor = .red
                            self.errorLabel.isHidden = false
                            self.indicator.isHidden = true
                            self.indicator.stopAnimating()
                        }
                        return // don't go any further.
                    } else {
                        // save to the cloud
                        publicDatabase.save(accountRecord, completionHandler: { (record, error) in
                            if error != nil {
                                DispatchQueue.main.async {
                                    self.errorLabel.text = "Connection error. Try again later."
                                    self.errorLabel.textColor = .red
                                    self.errorLabel.isHidden = false
                                    self.indicator.isHidden = true
                                    self.indicator.stopAnimating()
                                }
                                return
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
                            DispatchQueue.main.async {
                                self.errorLabel.text = "Connection error. Try again later."
                                self.errorLabel.textColor = .red
                                self.errorLabel.isHidden = false
                                self.indicator.isHidden = true
                                self.indicator.stopAnimating()
                            }
                            return
                        }
                        
                        // set userdefaults for first launch
                        let defaults = UserDefaults.standard
                        defaults.set(false, forKey: "FirstLaunch")
                        
                        // navigate to primary controller
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        let vc = storyboard.instantiateViewController(withIdentifier: "baseNavController")
                        
                        DispatchQueue.main.async {
                            self.present(vc, animated: true, completion: nil)
                        }
                    }
                }
            })
            
        } else { // fetch existing username/password combo and save locally
            let managedContext = appDelegate.persistentContainer.viewContext
            let accountEntity = NSEntityDescription.entity(forEntityName: "Account", in: managedContext)!
            let account = NSManagedObject(entity: accountEntity, insertInto: managedContext) as! Account
            
            let publicDatabase:CKDatabase = CKContainer.default().publicCloudDatabase
            let predicate = NSPredicate(format: "username = %@ AND password = %@", usernameField.text!, passwordField.text!)
            let query = CKQuery(recordType: "Accounts", predicate: predicate)
            
            publicDatabase.perform(query, inZoneWith: nil, completionHandler: { (results, error) in
                if error != nil {
                    DispatchQueue.main.async {
                        self.errorLabel.text = "Connection error. Try again later."
                        self.errorLabel.textColor = .red
                        self.errorLabel.isHidden = false
                        self.indicator.isHidden = true
                        self.indicator.stopAnimating()
                    }
                    return
                } else {
                    if (results?.count)! < 1 {
                        DispatchQueue.main.async { // show error, incorrect username password combo
                            self.errorLabel.text = "Incorrect username or password."
                            self.errorLabel.textColor = .red
                            self.errorLabel.isHidden = false
                            self.indicator.isHidden = true
                            self.indicator.stopAnimating()
                        }
                        return
                    } else { // save the username and password locally and log in
                        account.username = self.usernameField.text
                        account.password = self.passwordField.text
                        //account.id = accountRecord.recordID.recordName        set when record has been retrieved
                        
                        // save locally
                        do {
                            try managedContext.save()
                        } catch {
                            DispatchQueue.main.async {
                                self.errorLabel.text = "Connection error. Try again later."
                                self.errorLabel.textColor = .red
                                self.errorLabel.isHidden = false
                                self.indicator.isHidden = true
                                self.indicator.stopAnimating()
                            }
                            return
                        }
                        
                        // set userdefaults for first launch
                        let defaults = UserDefaults.standard
                        defaults.set(false, forKey: "FirstLaunch")
                        
                        // navigate to primary controller
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        let vc = storyboard.instantiateViewController(withIdentifier: "baseNavController")
                        
                        DispatchQueue.main.async {
                            self.present(vc, animated: true, completion: nil)
                        }
                    }
                }
            })
        }
    }
    
    //MARK: Text Field Delegate Methods
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if usernameField.text != "" && passwordField.text != "" {
            
        }
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        //textField.resignFirstResponder()
        
        //
        let nextTag=textField.tag+1;
        // Try to find next responder
        let nextResponder=textField.superview?.viewWithTag(nextTag) as UIResponder!
        
        if (nextResponder != nil){
            // Found next responder, so set it.
            nextResponder?.becomeFirstResponder()
        }
        else
        {
            // Not found, so remove keyboard
            textField.resignFirstResponder()
        }
        return false // We do not want UITextField to insert line-breaks.
    }
    
    // check changes in text fields to see if already exists
    func checkUsernameMatch(username: String) {
        
    }
}
