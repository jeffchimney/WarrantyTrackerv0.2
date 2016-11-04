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
    
    var tagArray: [String] = []
    var tagLabelArray: [UILabel] = []
    let maxSize = 10
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleTextField.delegate = self
        tagsTextField.delegate = self

        tagsTextField.addTarget(self, action: #selector(addTag(sender:)), for: UIControlEvents.editingChanged)
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
                let capitalizedTag = String(tag.characters.first!).uppercased() + String(tag.characters.dropFirst())
                if !tagArray.contains(capitalizedTag) {
                    tagArray.append(capitalizedTag)
                    
                    var spacer: CGFloat = 50
                    var counter = 0
                    var rowCounter = 0
                    for thisTag in tagArray {
                        if counter < maxSize {
                            counter += 1
                            // width is set at the bottom of the conditional
                            let label = UILabel()
                            label.backgroundColor = UIColor.red
                            if counter <= 4 {
                                switch counter {
                                case 1:
                                    label.center = CGPoint(x: spacer, y: 250)
                                case 2:
                                    label.center = CGPoint(x: spacer, y: 250)
                                case 3:
                                    label.center = CGPoint(x: spacer, y: 250)
                                case 4:
                                    label.center = CGPoint(x: spacer, y: 250)
                                    spacer = 50
                                default: break
                                }
                            } else {
                                switch counter {
                                case 5:
                                    label.center = CGPoint(x: spacer, y: 300)
                                case 6:
                                    label.center = CGPoint(x: spacer, y: 300)
                                case 7:
                                    label.center = CGPoint(x: spacer, y: 300)
                                case 8:
                                    label.center = CGPoint(x: spacer, y: 300)
                                default: break
                                }
                            }
                            print(label.intrinsicContentSize.width)
                            label.text = thisTag
                            label.sizeToFit()
                            self.view.addSubview(label)
                            tagLabelArray.append(label)
                            spacer = spacer + tagLabelArray[counter-1].frame.width
                        }
                    }
                }
                print(tagArray)
                tagsTextField.text = ""
            }
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
