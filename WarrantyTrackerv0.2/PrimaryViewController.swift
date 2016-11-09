
//
//  SecondViewController.swift
//  WarrantyTrackerv0.2
//
//  Created by Jeff Chimney on 2016-11-01.
//  Copyright © 2016 Jeff Chimney. All rights reserved.
//

import UIKit

class PrimaryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var warrantiesTableView: UITableView!
    let cellIdentifier = "WarrantyTableViewCell"
    var records = [Record]()
    let defaults = UserDefaults.standard

    override func viewDidLoad() {
        super.viewDidLoad()

        self.warrantiesTableView.delegate = self
        self.warrantiesTableView.dataSource = self
        
        //get your object from NSUserDefaults.
        if let loadedData = defaults.data(forKey: "records") {
            
            if let loadedRecords = NSKeyedUnarchiver.unarchiveObject(with: loadedData) as? [Record] {
                records = loadedRecords
            }
        }
        self.warrantiesTableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //get your object from NSUserDefaults.
        if let loadedData = UserDefaults().object(forKey: "records") {
            if let loadedRecords = NSKeyedUnarchiver.unarchiveObject(with: loadedData as! Data) {
                records = loadedRecords as! [Record]
            }
        }
        self.warrantiesTableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1 // maybe 2 if we want a separate section for expired warranties
    }
    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        <#code#>
//    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! WarrantyTableViewCell
        let record = records[indexPath.row]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        cell.title.text = record.title
        cell.descriptionView.text = record.description
        cell.warrantyStarts.text = dateFormatter.string(from: record.warrantyStarts!)
        cell.warrantyEnds.text = dateFormatter.string(from: record.warrantyEnds!)
        cell.warrantyImageView.image = record.itemImage
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return records.count
    }
}

