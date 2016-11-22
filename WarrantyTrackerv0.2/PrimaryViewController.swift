
//
//  SecondViewController.swift
//  WarrantyTrackerv0.2
//
//  Created by Jeff Chimney on 2016-11-01.
//  Copyright © 2016 Jeff Chimney. All rights reserved.
//

import UIKit
import CoreData

class PrimaryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var warrantiesTableView: UITableView!
    let cellIdentifier = "WarrantyTableViewCell"
    var records: [NSManagedObject] = []
    let defaults = UserDefaults.standard

    override func viewDidLoad() {
        super.viewDidLoad()

        self.warrantiesTableView.delegate = self
        self.warrantiesTableView.dataSource = self
        
        //get your object from CoreData
        
        self.warrantiesTableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Record")
        
        do {
            records = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        //get your object from CoreData
        
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
        let record = records[indexPath.row] as! Record
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        cell.title.text = record.title
        cell.descriptionView.text = record.descriptionString
        cell.warrantyStarts.text = dateFormatter.string(from: record.warrantyStarts! as Date)
        cell.warrantyEnds.text = dateFormatter.string(from: record.warrantyEnds! as Date)
        let recordImage = UIImage(data: record.itemImage as! Data)
        cell.warrantyImageView.image = recordImage
        
        print(record.tags ?? "None found")
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return records.count
    }
}

