//
//  EditDateController.swift
//  WarrantyTrackerv0.2
//
//  Created by Jeff Chimney on 2016-12-12.
//  Copyright © 2016 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit

class EditDateController: UIViewController {
    
    @IBOutlet weak var datePicker: UIDatePicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        datePicker.datePickerMode = UIDatePickerMode.date
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // send data back to previous controller
    }
}
