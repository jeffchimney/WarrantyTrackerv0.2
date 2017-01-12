//
//  WarrantyBeginsEndsViewController.swift
//  WarrantyTrackerv0.2
//
//  Created by Jeff Chimney on 2016-11-01.
//  Copyright © 2016 Jeff Chimney. All rights reserved.
//

import UIKit

class WarrantyBeginsEndsViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    // variables that have been passed forward
    var itemImageData: Data! = nil
    var receiptImageData: Data! = nil
    //
    
    @IBOutlet weak var beginsPicker: UIDatePicker!
    @IBOutlet weak var selectedStartDate: UILabel!
    @IBOutlet weak var selectedEndDate: UILabel!
    @IBOutlet weak var nextButton: UIBarButtonItem!
    @IBOutlet weak var saveDateButton: UIButton!
    @IBOutlet weak var warrantyBeginsLabel: UILabel!
    @IBOutlet weak var warrantyEndsLabel: UILabel!
    @IBOutlet weak var navBar: UINavigationItem!
    //@IBOutlet weak var numberOfWeeksSegment: UISegmentedControl!
    @IBOutlet weak var daysBeforePicker: UIPickerView!
    @IBOutlet weak var remindMeLabel1: UILabel!
    @IBOutlet weak var remindMeLabel2: UILabel!
    
    var startDatePicked = false
    var endDatePicked = false
    var hasWarranty = true
    var pickerData: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        beginsPicker.datePickerMode = UIDatePickerMode.date
        selectedStartDate.text = ""
        selectedEndDate.text = ""
        
        selectedStartDate.textColor = UIColor.red
        selectedEndDate.textColor = UIColor.red
        saveDateButton.setTitle("Set Start Date", for: .normal)
        warrantyBeginsLabel.isHidden = true
        warrantyEndsLabel.isHidden = true
        selectedEndDate.isHidden = true
        navBar.title = "Warranty"
        nextButton.title = "Skip"
        
        remindMeLabel1.isHidden = true
        daysBeforePicker.isHidden = true
        remindMeLabel2.isHidden = true
        
        for index in 1...31 {
            pickerData.append(String(index))
        }
        
        daysBeforePicker.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        daysBeforePicker.selectRow(6, inComponent: 0, animated: false)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func pickerChanged(_ sender: Any) {
        if startDatePicked { // make sure end date is never earlier than start date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d, yyyy"
            print(beginsPicker.date.compare(dateFormatter.date(from: selectedStartDate.text!)!) == .orderedAscending)

            if beginsPicker.date.compare(dateFormatter.date(from: selectedStartDate.text!)!) == .orderedAscending {
                beginsPicker.date = dateFormatter.date(from: selectedStartDate.text!)!
            }
        }
    }
    
    @IBAction func saveDateButtonPressed(_ sender: Any) {
        if startDatePicked == false && endDatePicked == false { // set start date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d, yyyy"
            let startDate = dateFormatter.string(from: beginsPicker.date)
            self.selectedStartDate.text = startDate
            
            selectedStartDate.isHidden = false
            warrantyBeginsLabel.isHidden = false
            saveDateButton.setTitle("Set End Date", for: .normal)
            startDatePicked = true
            nextButton.title = "Skip"
        } else if startDatePicked == true && endDatePicked == false { // set end date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d, yyyy"
            let endDate = dateFormatter.string(from: beginsPicker.date)
            self.selectedEndDate.text = endDate
            
            warrantyEndsLabel.isHidden = false
            selectedEndDate.isHidden = false
            saveDateButton.setTitle("Change Dates", for: .normal)
            endDatePicked = true
            nextButton.title = "Next"
            
            remindMeLabel1.isHidden = false
            daysBeforePicker.isHidden = false
            remindMeLabel2.isHidden = false
        } else if startDatePicked == true && endDatePicked == true { // clear both dates and start over
            self.selectedStartDate.text = ""
            self.selectedEndDate.text = ""
            warrantyEndsLabel.isHidden = true
            selectedStartDate.isHidden = true
            selectedEndDate.isHidden = true
            startDatePicked = false
            endDatePicked = false
            nextButton.title = "Skip"
        }
        
    }
    
    //MARK: Picker View Data Sources and Delegates
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetails" {
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d, yyyy"
            
            if let nextViewController = segue.destination as? WarrantyDetailsViewController { // pass data to the next view controller
                if itemImageData != nil {
                    nextViewController.itemImageData = itemImageData
                }
                if receiptImageData != nil {
                    nextViewController.receiptImageData = receiptImageData
                }
                if hasWarranty { // pass along warranty dates
                    nextViewController.startDate = dateFormatter.date(from: selectedStartDate.text!)
                    nextViewController.endDate = dateFormatter.date(from: selectedEndDate.text!)
                    nextViewController.daysBeforeReminder = Int(daysBeforePicker.selectedRow(inComponent: 0)+1)
                }
            }
        }
    }
}

