//
//  WarrantyDetailsViewController.swift
//  WarrantyTrackerv0.2
//
//  Created by Jeff Chimney on 2016-11-01.
//  Copyright © 2016 Jeff Chimney. All rights reserved.
//

import UIKit
import CoreData
import EventKit

class WarrantyDetailsViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    // variables that have been passed forward
    var itemImageData: Data! = nil
    var receiptImageData: Data! = nil
    var startDate: Date? = nil
    var endDate: Date? = nil
    var hasWarranty: Bool = true
    //
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var tagsTextField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var navBar: UINavigationItem!
    @IBOutlet weak var numberOfWeeksSegment: UISegmentedControl!
    @IBOutlet weak var tagsPickerView: UIPickerView!
    @IBOutlet weak var removeTagButton: UIButton!
    
    var tagArray = [String]()
    var tagLabelArray = [UILabel]()
    let maxSize = 10
    
    let defaults = UserDefaults.standard
    let eventStore = EKEventStore()
    var calendars: [EKCalendar]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tagsPickerView.dataSource = self;
        self.tagsPickerView.delegate = self;
        
        removeTagButton.isHidden = true
        saveButton.isEnabled = false
        
        titleTextField.delegate = self
        tagsTextField.delegate = self
        tagsTextField.addTarget(self, action: #selector(addTag(sender:)), for: UIControlEvents.editingChanged)
        navBar.title = "Details"
        descriptionTextField.text = ""
        
        // to find and use the calendar for events:
        //let calendar = checkCalendar()
        //var calEvent = EKEvent(eventStore: eventStore)
        //calEvent.calendar = calendar
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
                addTagToArray(usingString: tag)
            }
        }
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        //let record: Record = Record(with: titleTextField.text!, description: descriptionTextField.text, tags: tagArray, warrantyStarts: startDate, warrantyEnds: endDate, itemImage: itemImage, receiptImage: receiptImage, weeksBeforeReminder: numberOfWeeksSegment.selectedSegmentIndex, hasWarranty: hasWarranty)
        
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext

        let recordEntity = NSEntityDescription.entity(forEntityName: "Record", in: managedContext)!
        let tagEntity = NSEntityDescription.entity(forEntityName: "Tag", in: managedContext)!
        
        let record = NSManagedObject(entity: recordEntity, insertInto: managedContext) as! Record
        
        record.title = titleTextField.text!
        record.descriptionString = descriptionTextField.text!
        //record.tags = tagArray
        record.warrantyStarts = startDate as NSDate?
        record.warrantyEnds = endDate as NSDate?
        record.itemImage = itemImageData as NSData?
        record.receiptImage = receiptImageData as NSData?
        record.weeksBeforeReminder = Int32(numberOfWeeksSegment.selectedSegmentIndex)
        record.hasWarranty = hasWarranty
        
        // add tags
        for tag in tagArray {
            let newTag = NSManagedObject(entity: tagEntity, insertInto: managedContext) as! Tag
            
            newTag.tag = tag
            record.addToTags(newTag)
        }

        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        self.navigationController!.popToRootViewController(animated: true)
    }
    
    private func addTagToArray(usingString tag:String) {
        let capitalizedTag = String(tag.characters.first!).uppercased() + String(tag.characters.dropFirst())
        if !tagArray.contains(capitalizedTag) {
            tagArray.append(capitalizedTag)
        }
        tagsTextField.text = ""
        tagsPickerView.reloadAllComponents()
        removeTagButton.isHidden = false
        // enable save button if there is text in the title field
        if titleTextField.text != "" && tagArray.count != 0 {
            saveButton.isEnabled = true
        }
    }
    
    @IBAction func removeButtonPressed(_ sender: Any) {
        print(tagsPickerView.selectedRow(inComponent: 0).description)
        tagArray.remove(at: tagsPickerView.selectedRow(inComponent: 0))
        tagsPickerView.reloadAllComponents()
    }
    
    func checkCalendar() -> EKCalendar {
        var retCal: EKCalendar?
        
        let calendars = eventStore.calendars(for: EKEntityType.event) // Grab every calendar the user has
        var exists: Bool = false
        for calendar in calendars { // Search all these calendars
            if calendar.title == "WarrantyTracker" {
                exists = true
                retCal = calendar
            }
        }
        
        if !exists {
            let newCalendar = EKCalendar(for:EKEntityType.event, eventStore:eventStore)
            newCalendar.title="WarrantyTracker"
            newCalendar.source = eventStore.defaultCalendarForNewEvents.source
            do {
                try eventStore.saveCalendar(newCalendar, commit:true)
            } catch {
                print("Couldn't add calendar")
            }
            retCal = newCalendar
        }
        
        return retCal!
    }
    
    func requestAccessToCalendar() {
        eventStore.requestAccess(to: EKEntityType.event, completion: {
            (accessGranted: Bool, error: Error?) in
            
            if accessGranted == true {
                DispatchQueue.main.async(execute: {
                    self.loadCalendars()
                })
            } else {
                DispatchQueue.main.async(execute: {
                    
                })
            }
        })
    }
    
    func loadCalendars() {
        calendars = eventStore.calendars(for: EKEntityType.event)
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
            addTagToArray(usingString: textField.text!)
        }
        textField.resignFirstResponder()
        return true
    }
    
    //MARK: Picker View Delegate Methods
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return tagArray.count;
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return tagArray[row]
    }
}
