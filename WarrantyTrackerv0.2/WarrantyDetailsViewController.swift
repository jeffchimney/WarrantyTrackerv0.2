//
//  WarrantyDetailsViewController.swift
//  WarrantyTrackerv0.2
//
//  Created by Jeff Chimney on 2016-11-01.
//  Copyright © 2016 Jeff Chimney. All rights reserved.
//

import UIKit
import CoreData
import CloudKit
import EventKit

class WarrantyDetailsViewController: UITableViewController, UITextFieldDelegate {
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var nextButton: UIBarButtonItem!
    @IBOutlet weak var navBar: UINavigationItem!
    
    let defaults = UserDefaults.standard
    let eventStore = EKEventStore()
    var calendars: [EKCalendar]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nextButton.isEnabled = false
        
        titleTextField.delegate = self
        descriptionTextField.delegate = self
        navBar.title = "Details"
        descriptionTextField.text = ""
        
        titleTextField.autocapitalizationType = .words
        descriptionTextField.autocapitalizationType = .sentences
        
        titleTextField.tag = 0
        descriptionTextField.tag = 1
        
        titleTextField.becomeFirstResponder()
        
        titleTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        descriptionTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        navigationController?.isToolbarHidden = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    //MARK: Text Field Delegate Methods
    
    func textFieldDidBeginEditing(_ textField: UITextField) {

    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if titleTextField.isFirstResponder {
            descriptionTextField.becomeFirstResponder()
        } else if descriptionTextField.isFirstResponder {
            // segue to next controller
            descriptionTextField.resignFirstResponder()
        }
        return false // We do not want UITextField to insert line-breaks.
    }
    
    func textFieldDidChange(_ textField: UITextField) {
        if titleTextField.text != "" && descriptionTextField.text != "" {
            nextButton.isEnabled = true
        } else {
            nextButton.isEnabled = false
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "toImage") {
            if let nextViewController = segue.destination as? NewItemViewController {
                nextViewController.titleString = titleTextField.text!
                nextViewController.descriptionString = descriptionTextField.text!
            }
        }
    }
}
