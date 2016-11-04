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
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var tagsTextField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var navBar: UINavigationItem!
    
    var tagArray: [String] = []
    var tagLabelArray: [UILabel] = []
    let maxSize = 10
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleTextField.delegate = self
        tagsTextField.delegate = self

        tagsTextField.addTarget(self, action: #selector(addTag(sender:)), for: UIControlEvents.editingChanged)
        saveButton.isEnabled = false
        navBar.title = "Details"
        descriptionTextField.text = ""
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    @objc private func addTag(sender: UITextField) {
        if tagsTextField.text != "" {
            let enteredText = tagsTextField.text!
            let lastChar = enteredText.substring(from:enteredText.index(enteredText.endIndex, offsetBy: -1))
            
            if lastChar == "," || lastChar == " " {
                let tag = enteredText.substring(to: enteredText.index(enteredText.endIndex, offsetBy: -1))
                addTagAndLabel(usingString: tag)
            }
        }
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
    }
    
    private func addTagAndLabel(usingString tag:String) {
        let capitalizedTag = String(tag.characters.first!).uppercased() + String(tag.characters.dropFirst())
        if !tagArray.contains(capitalizedTag) {
            tagArray.append(capitalizedTag)
            
            var spacer: CGFloat = 30
            var counter = 0
            var rowCounter = 0
            var offset = 100 + (rowCounter*25)
            // set width and text of label
            let label = UILabel()
            label.backgroundColor = UIColor.red
            label.text = capitalizedTag
            label.sizeToFit()
            tagLabelArray.append(label)
            for thisLabel in tagLabelArray {
                if counter < maxSize {
                    counter += 1
                    thisLabel.center = CGPoint(x: spacer, y: CGFloat(offset))
                    
                    if (thisLabel.center.x + thisLabel.frame.width/2) > self.view.frame.width-30 { // add label to the next row
                        rowCounter += 1
                        spacer = 30
                        offset = 250 + (rowCounter*25)
                        thisLabel.center = CGPoint(x: spacer, y: CGFloat(offset))
                    } else {
                        if tagLabelArray.count > 1 { // if there are two items in the array, calculate space between
                            spacer = spacer + tagLabelArray[counter-1].frame.width + tagLabelArray[counter].frame.width
                            thisLabel.center = CGPoint(x: spacer, y: CGFloat(offset))
                        } else { // if there is one item in the array, move it away from the edge of the screen
                            thisLabel.center = CGPoint(x: spacer, y: CGFloat(offset))
                        }
                    }
                    self.view.addSubview(label)
                }
            }
        }
        print(tagArray)
        print(tagLabelArray.count)
        tagsTextField.text = ""
    }
    
    //MARK: Text Field Delegate Methods
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if titleTextField.text != "" && tagArray.count != 0 {
            saveButton.isEnabled = true
        }
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField.text != "" && textField == tagsTextField) {
            addTagAndLabel(usingString: textField.text!)
        }
        textField.resignFirstResponder()
        return true
    }
}
