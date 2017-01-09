//
//  DeletedAndExpiredController.swift
//  WarrantyTrackerv0.2
//
//  Created by Jeff Chimney on 2016-12-21.
//  Copyright © 2016 Jeff Chimney. All rights reserved.
//

import UIKit
import CoreData

class DeletedAndExpiredController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let cellIdentifier = "WarrantyTableViewCell"
    var fetchedRecords: [NSManagedObject] = []
    var expiredRecords: [Record] = []
    var deletedRecords: [Record] = []
    var sections: [[Record]] = [[]]
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.reloadData()
        
        navigationController?.setToolbarHidden(true, animated: false)
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
            fetchedRecords = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        //get your object from CoreData
        for eachRecord in fetchedRecords {
            let record = eachRecord as! Record
            
            if record.recentlyDeleted {
                deletedRecords.append(record)
            } else if record.expired {
                expiredRecords.append(record)
            }
        }
        tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Expired"
        } else {
            return "Recently Deleted"
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! WarrantyTableViewCell
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        if indexPath.section == 0 {
            if expiredRecords.count == 0 {
                cell.title.text = "None found."
                cell.warrantyStarts.isHidden = true
                cell.warrantyEnds.isHidden = true
                cell.warrantyImageView.isHidden = true
                cell.dashLabel.isHidden = true
            } else {
                expiredRecords.sort(by:{ $0.warrantyEnds?.compare($1.warrantyEnds as! Date) == .orderedDescending})
                let record = expiredRecords[indexPath.row]
                cell.title.text = record.title
                cell.warrantyStarts.text = dateFormatter.string(from: record.warrantyStarts! as Date)
                cell.warrantyEnds.text = dateFormatter.string(from: record.warrantyEnds! as Date)
                let recordImage = UIImage(data: record.itemImage as! Data)
                cell.warrantyImageView.image = recordImage
            }
        } else {
            if deletedRecords.count == 0 {
                cell.title.text = "None found."
                cell.warrantyStarts.isHidden = true
                cell.warrantyEnds.isHidden = true
                cell.warrantyImageView.isHidden = true
                cell.dashLabel.isHidden = true
            }else {
                deletedRecords.sort(by:{ $0.dateDeleted?.compare($1.dateDeleted as! Date) == .orderedDescending})
                let record = deletedRecords[indexPath.row]
                cell.title.text = record.title
                cell.warrantyStarts.text = dateFormatter.string(from: record.warrantyStarts! as Date)
                cell.warrantyEnds.text = dateFormatter.string(from: record.warrantyEnds! as Date)
                let recordImage = UIImage(data: record.itemImage as! Data)
                cell.warrantyImageView.image = recordImage
            }
        }
        
        cell.warrantyImageView.contentMode = .scaleAspectFit
        cell.title.textColor = cell.tintColor
        cell.backgroundColor = UIColor(colorLiteralRed: 189, green: 195, blue: 201, alpha: 1.0)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if expiredRecords.count == 0 {
                return 0
            } else {
                return expiredRecords.count
            }
        } else {
            if deletedRecords.count == 0 {
                return 0
            } else {
                return deletedRecords.count
            }
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.deleteRows(at: [indexPath], with: .fade)
            if indexPath.section == 0 { // expired
                expiredRecords.remove(at: indexPath.row)
            } else { // recently deleted
                deletedRecords.remove(at: indexPath.row)
            }
        }
    }
}

