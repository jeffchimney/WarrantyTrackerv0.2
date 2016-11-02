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
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var saveDateButton: UIButton!
    @IBOutlet weak var warrantyEndsLabel: UILabel!
    
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
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func beginsPickerChanged(_ sender: Any) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        let startDate = dateFormatter.string(from: beginsPicker.date)
        self.selectedStartDate.text = startDate
    }
    
    @IBAction func unwindSegue(segue:UIStoryboardSegue) {
        
    }
    
    @IBAction func saveDateButtonPressed(_ sender: Any) {
        if startDatePicked == false && endDatePicked == false {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d, yyyy"
            let startDate = dateFormatter.string(from: beginsPicker.date)
            self.selectedStartDate.text = startDate
            
            selectedStartDate.isHidden = false
            warrantyEndsLabel.isHidden = false
            saveDateButton.setTitle("Set End Date", for: .normal)
            startDatePicked = true
        } else if startDatePicked == true && endDatePicked == false {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d, yyyy"
            let endDate = dateFormatter.string(from: beginsPicker.date)
            self.selectedEndDate.text = endDate
            
            warrantyEndsLabel.isHidden = false
            selectedEndDate.isHidden = false
            saveDateButton.setTitle("Change Dates", for: .normal)
            endDatePicked = true
        } else if startDatePicked == true && endDatePicked == true {
            self.selectedStartDate.text = ""
            self.selectedEndDate.text = ""
            warrantyEndsLabel.isHidden = true
            selectedStartDate.isHidden = true
            selectedEndDate.isHidden = true
            startDatePicked = false
            endDatePicked = false
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetails" {
            if let nextViewController = segue.destination as? WarrantyDetailsViewController {
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

