//
//  WarrantyDetailsViewController.swift
//  WarrantyTrackerv0.2
//
//  Created by Jeff Chimney on 2016-11-01.
//  Copyright © 2016 Jeff Chimney. All rights reserved.
//

import UIKit

class WarrantyDetailsViewController: UIViewController, UITextFieldDelegate {
    
    // variables that have been passed forward
    var itemImage: UIImage! = nil
    var receiptImage: UIImage! = nil
    var startDate: String = ""
    var endDate: String = ""
    //
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var tagsTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleTextField.delegate = self
        tagsTextField.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    private func addTag() {
        if tagsTextField.text == "" {
            
        }
    }
    
    //MARK: Text Field Delegate Methods
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
