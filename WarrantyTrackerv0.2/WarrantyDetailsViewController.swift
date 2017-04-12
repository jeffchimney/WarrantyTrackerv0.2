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

class WarrantyDetailsViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    // variables that have been passed forward
    var itemImageData: Data! = nil
    var receiptImageData: Data! = nil
    var startDate: Date? = nil
    var endDate: Date? = nil
    var daysBeforeReminder: Int!
    var hasWarranty: Bool = true
    //
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var tagsTextField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var navBar: UINavigationItem!
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
        descriptionTextField.delegate = self
        tagsTextField.delegate = self
        tagsTextField.addTarget(self, action: #selector(addTag(sender:)), for: UIControlEvents.editingChanged)
        navBar.title = "Details"
        descriptionTextField.text = ""
        
        titleTextField.autocapitalizationType = .words
        descriptionTextField.autocapitalizationType = .sentences
        tagsTextField.autocapitalizationType = .sentences
        
        titleTextField.tag = 0
        descriptionTextField.tag = 1
        tagsTextField.tag = 2
        
        titleTextField.becomeFirstResponder()
        
        requestAccessToCalendar()
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
        record.daysBeforeReminder = Int32(daysBeforeReminder)
        record.hasWarranty = hasWarranty
        record.dateCreated = Date() as NSDate?
        record.lastUpdated = Date() as NSDate?
        record.recentlyDeleted = false
        record.expired = false
        record.recordID = UUID().uuidString
        
        // add tags
        for tag in tagArray {
            let newTag = NSManagedObject(entity: tagEntity, insertInto: managedContext) as! Tag
            
            newTag.tag = tag
            record.addToTags(newTag)
        }
        
        // to find and use the calendar for events:
        let calendar = checkCalendar()
        let newEvent = EKEvent(eventStore: eventStore)
        newEvent.calendar = calendar
        newEvent.title = titleTextField.text! + " Warranty Expires"
        newEvent.notes = "Is your item still working properly?  Its warranty expires today."
        newEvent.startDate = endDate!
        newEvent.endDate = endDate!
        newEvent.isAllDay = true
        // configure alarm for event
        let daysToSubtract = -(daysBeforeReminder+1)
        
        var addingPeriod = DateComponents()
        addingPeriod.day = daysToSubtract
        addingPeriod.hour = 12
        
        let userCalendar = NSCalendar.current
        let alarmDate = userCalendar.date(byAdding: addingPeriod, to: endDate!) // this is really subtracting...
        
        let alarm = EKAlarm(absoluteDate: alarmDate!)
        newEvent.addAlarm(alarm)
        
        // try to save the event
        do {
            try eventStore.save(newEvent, span: .thisEvent, commit: true)
            record.eventIdentifier = newEvent.eventIdentifier
            print("Event Identifier: " + newEvent.eventIdentifier)
            self.dismiss(animated: true, completion: nil)
        } catch {
            let alert = UIAlertController(title: "Event could not be saved", message: (error as NSError).localizedDescription, preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(OKAction)
            
            self.present(alert, animated: true, completion: nil)
        }
        
        // Save the created Record object
        do {
            try managedContext.save()
            // check if the user is signed in, if not then there is nothing to refresh.
            if (UserDefaultsHelper.isSignedIn()) {
                // check what the current connection is.  If wifi, refresh.  If data, and sync by data is enabled, refresh.
                let conn = UserDefaultsHelper.currentConnection()
                if (conn == "wifi" || (conn == "data" && UserDefaultsHelper.canSyncUsingData())) {
                    CloudKitHelper.importCDRecord(cdRecord: record, context: managedContext)
                } else {
                    // queue up the record to sync when you have a good connection
                    UserDefaultsHelper.addRecordToQueue(recordID: record.recordID!)
                }
            }
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
        tagsPickerView.selectRow(tagArray.count-1, inComponent: 0, animated: true)
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
                    // Are you sure?
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
        //textField.resignFirstResponder()
        
        //
        let nextTage=textField.tag+1;
        // Try to find next responder
        let nextResponder=textField.superview?.viewWithTag(nextTage) as UIResponder!
        
        if (nextResponder != nil){
            // Found next responder, so set it.
            nextResponder?.becomeFirstResponder()
        }
        return false // We do not want UITextField to insert line-breaks.
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
