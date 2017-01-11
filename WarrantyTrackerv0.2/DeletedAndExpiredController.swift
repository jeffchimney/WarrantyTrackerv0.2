//
//  DeletedAndExpiredController.swift
//  WarrantyTrackerv0.2
//
//  Created by Jeff Chimney on 2016-12-21.
//  Copyright © 2016 Jeff Chimney. All rights reserved.
//

import UIKit
import CoreData

class DeletedAndExpiredController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIViewControllerPreviewingDelegate {
    
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
        
        // register for previewing with 3d touch
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: view)
        } else {
            print("3D Touch Not Available")
        }
        
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
                cell.isUserInteractionEnabled = false
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
                cell.isUserInteractionEnabled = false
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
                return 1
            } else {
                return expiredRecords.count
            }
        } else {
            if deletedRecords.count == 0 {
                return 1
            } else {
                return deletedRecords.count
            }
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        // recover record on press recover
        let recover = UITableViewRowAction(style: .normal, title: "Recover") { action, index in
            if indexPath.section == 1 { // recently deleted
                self.setRecentlyDeletedFalse(for: self.deletedRecords[indexPath.row])
                tableView.reloadData()
            }
        }
        recover.backgroundColor = tableView.tintColor
        
        // delete record on press delete
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { action, index in
            if indexPath.section == 0 { // expired
                
                self.deleteFromCoreData(record: self.expiredRecords[indexPath.row])
                self.expiredRecords.remove(at: indexPath.row)
            } else { // recently deleted
                self.deleteFromCoreData(record: self.deletedRecords[indexPath.row])
                self.deletedRecords.remove(at: indexPath.row)
            }
            tableView.reloadData()
        }
        delete.backgroundColor = .red
        
        if indexPath.section == 1 {
            return [delete, recover]
        } else {
            return [delete]
        }
    }
    
    func deleteFromCoreData(record: Record) {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        var returnedRecords: [NSManagedObject] = []
        
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Record")
        
        do {
            returnedRecords = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        for thisRecord in returnedRecords {
            if record == thisRecord {
                managedContext.delete(thisRecord)
                do {
                    try managedContext.save()
                } catch {
                    print("Error deleting record")
                }
            }
        }
    }
    
    func setRecentlyDeletedFalse(for record: Record) {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        var returnedRecords: [NSManagedObject] = []
        
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Record")
        
        do {
            returnedRecords = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        for thisRecord in returnedRecords {
            if record == thisRecord {
                let thisRecord = thisRecord as! Record
                thisRecord.recentlyDeleted = false
                deletedRecords.remove(at: deletedRecords.index(of: record)!)
                tableView.reloadData()
                do {
                    try managedContext.save()
                } catch {
                    print("Error deleting record")
                }
            }
        }
    }
    
    //MARK: Peek and Pop methods
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        // convert point from position in self.view to position in warrantiesTableView
        let cellPosition = tableView.convert(location, from: self.view)
        
        guard let indexPath = tableView.indexPathForRow(at: cellPosition),
            let cell = tableView.cellForRow(at: indexPath) else {
                return nil
        }
        
        guard let recoverViewController =
            storyboard?.instantiateViewController(
                withIdentifier: "recoverCardViewController") as?
            RecoverCardViewController else {
                return nil
        }
        
        let selectedRecord = deletedRecords[indexPath.row]
        
        recoverViewController.record = selectedRecord
            recoverViewController.preferredContentSize =
            CGSize(width: 0.0, height: 500)
        
        previewingContext.sourceRect = view.convert(cell.frame, from: tableView)
        
        return recoverViewController
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        //show(viewControllerToCommit, sender: self)
    }
}

