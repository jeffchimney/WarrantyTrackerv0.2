//
//  WarrantyBeginsEndsViewController.swift
//  WarrantyTrackerv0.2
//
//  Created by Jeff Chimney on 2016-11-01.
//  Copyright © 2016 Jeff Chimney. All rights reserved.
//

import UIKit

class WarrantyBeginsEndsViewController: UIViewController {
    
    // variables that have been passed forward
    var itemImage: UIImage! = nil
    var receiptImage: UIImage! = nil
    //
    
    @IBOutlet weak var beginsPicker: UIDatePicker!
    @IBOutlet weak var selectedStartDate: UILabel!
    @IBOutlet weak var selectedEndDate: UILabel!
    @IBOutlet weak var nextButton: UIBarButtonItem!
    @IBOutlet weak var saveDateButton: UIButton!
    @IBOutlet weak var warrantyEndsLabel: UILabel!
    @IBOutlet weak var navBar: UINavigationItem!
    
    var startDatePicked = false
    var endDatePicked = false
    var hasWarranty = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        beginsPicker.datePickerMode = UIDatePickerMode.date
        selectedStartDate.text = ""
        selectedEndDate.text = ""
        
        selectedStartDate.textColor = UIColor.red
        selectedEndDate.textColor = UIColor.red
        saveDateButton.setTitle("Set Start Date", for: .normal)
        warrantyEndsLabel.isHidden = true
        selectedEndDate.isHidden = true
        navBar.title = "Warranty"
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
            warrantyEndsLabel.isHidden = false
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetails" {
            if let nextViewController = segue.destination as? WarrantyDetailsViewController { // pass data to the next view controller
                if itemImage != nil {
                    nextViewController.itemImage = itemImage
                }
                if receiptImage != nil {
                    nextViewController.receiptImage = receiptImage
                }
                nextViewController.startDate = selectedStartDate.text!
                nextViewController.endDate = selectedEndDate.text!
            }
        }
    }
}

