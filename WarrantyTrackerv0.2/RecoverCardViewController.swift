//
//  RecoverCardViewController.swift
//  WarrantyTrackerv0.2
//
//  Created by Jeff Chimney on 2017-01-09.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit

class RecoverCardViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    var record: Record!
    
    override func viewDidLoad() {
        imageView.image = UIImage(data: record.itemImage as! Data)
    }
}
