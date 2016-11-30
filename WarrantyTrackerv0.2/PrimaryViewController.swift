
//
//  SecondViewController.swift
//  WarrantyTrackerv0.2
//
//  Created by Jeff Chimney on 2016-11-01.
//  Copyright © 2016 Jeff Chimney. All rights reserved.
//

import UIKit
import CoreData

class PrimaryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UIViewControllerPreviewingDelegate {
    
    let searchController = UISearchController(searchResultsController: nil)
    var searchActive = false

    @IBOutlet weak var sortBySegmentControl: UISegmentedControl!
    @IBOutlet weak var warrantiesTableView: UITableView!
    let cellIdentifier = "WarrantyTableViewCell"
    var fetchedRecords: [NSManagedObject] = []
    var records: [Record] = []
    var filteredRecords: [Record] = []
    var recentlyDeletedRecords: [Record] = []
    var expiredRecords: [Record] = []
    var sections: [[Record]] = [[]]
    let sectionHeaders = ["Valid", "Recently Deleted", "Expired"]
    var selectedRecord: Record!
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.warrantiesTableView.delegate = self
        self.warrantiesTableView.dataSource = self
        
        // sorted by recent by default
        sortBySegmentControl.selectedSegmentIndex = 0
        
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let recordEntity = NSEntityDescription.entity(forEntityName: "Record", in: managedContext)!
        
        let record = NSManagedObject(entity: recordEntity, insertInto: managedContext) as! Record
        let record2 = NSManagedObject(entity: recordEntity, insertInto: managedContext) as! Record
        let record3 = NSManagedObject(entity: recordEntity, insertInto: managedContext) as! Record
        let record4 = NSManagedObject(entity: recordEntity, insertInto: managedContext) as! Record
        let record5 = NSManagedObject(entity: recordEntity, insertInto: managedContext) as! Record
        
        record.title = "Test"
        record.descriptionString = "Test"
        //record.tags = tagArray
        record.warrantyStarts = NSDate()
        record.warrantyEnds = NSDate()
        record.itemImage = NSData()
        record.receiptImage = NSData()
        record.weeksBeforeReminder = 2
        record.hasWarranty = true
        record.dateCreated = Date() as NSDate?
        record.recentlyDeleted = false
        record.expired = false
        
        record2.title = "Test2"
        record2.descriptionString = "Test2"
        //record.tags = tagArray
        record2.warrantyStarts = NSDate()
        record2.warrantyEnds = NSDate()
        record2.itemImage = NSData()
        record2.receiptImage = NSData()
        record2.weeksBeforeReminder = 2
        record2.hasWarranty = true
        record2.dateCreated = Date() as NSDate?
        record2.recentlyDeleted = false
        record2.expired = false
        
        record3.title = "Test3"
        record3.descriptionString = "Test3"
        //record.tags = tagArray
        record3.warrantyStarts = NSDate()
        record3.warrantyEnds = NSDate()
        record3.itemImage = NSData()
        record3.receiptImage = NSData()
        record3.weeksBeforeReminder = 2
        record3.hasWarranty = true
        record3.dateCreated = Date() as NSDate?
        record3.recentlyDeleted = false
        record3.expired = false
        
        record4.title = "Test4"
        record4.descriptionString = "Test4"
        //reco4d.tags = tagArray
        record4.warrantyStarts = NSDate()
        record4.warrantyEnds = NSDate()
        record4.itemImage = NSData()
        record4.receiptImage = NSData()
        record4.weeksBeforeReminder = 2
        record4.hasWarranty = true
        record4.dateCreated = Date() as NSDate?
        record4.recentlyDeleted = false
        record4.expired = false
        
        record5.title = "Test5"
        record5.descriptionString = "Test5"
        //record.tags = tagArray
        record5.warrantyStarts = NSDate()
        record5.warrantyEnds = NSDate()
        record5.itemImage = NSData()
        record5.receiptImage = NSData()
        record5.weeksBeforeReminder = 2
        record5.hasWarranty = true
        record5.dateCreated = Date() as NSDate?
        record5.recentlyDeleted = false
        record5.expired = false
        
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        
        self.warrantiesTableView.reloadData()
        
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        definesPresentationContext = true
        navigationItem.titleView = searchController.searchBar
        searchController.searchBar.delegate = self
        
        // register for previewing with 3d touch
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: view)
        } else {
            print("3D Touch Not Available")
        }
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
        records = []
        for eachRecord in fetchedRecords {
            let record = eachRecord as! Record
            
            if record.recentlyDeleted {
                recentlyDeletedRecords.append(record)
            } else if record.expired {
                expiredRecords.append(record)
            } else { // add to active records list
                records.append(record)
            }
        }
        
        sections = [records, recentlyDeletedRecords, expiredRecords]
        
        self.warrantiesTableView.reloadData()
    }
    
//    func delete(withDateTime date: NSDate) {
//        guard let appDelegate =
//            UIApplication.shared.delegate as? AppDelegate else {
//                return
//        }
//        let managedContext =
//            appDelegate.persistentContainer.viewContext
//        let fetchRequest =
//            NSFetchRequest<NSManagedObject>(entityName: "Record")
//        fetchRequest.predicate = NSPredicate(format: "dateCreated==%@", date)
//        let object = try! managedContext.fetch(fetchRequest)
//        managedContext.delete(object[0]) // delete first returned object
//    }
    
    @IBAction func selectedSegmentChanged(_ sender: Any) {
        warrantiesTableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionHeaders[section]
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if searchActive {
            selectedRecord = filteredRecords[indexPath.row]
            performSegue(withIdentifier: "toCellDetails", sender: self)
        } else {
            selectedRecord = records[indexPath.row]
            performSegue(withIdentifier: "toCellDetails", sender: self)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! WarrantyTableViewCell
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        if searchActive {
            sections = [filteredRecords, recentlyDeletedRecords, expiredRecords]
            if sortBySegmentControl.selectedSegmentIndex == 0 {
                sections[indexPath.section].sort(by:{ $0.dateCreated?.compare($1.dateCreated as! Date) == .orderedDescending})
                let record = sections[indexPath.section][indexPath.row]
                cell.title.text = record.title
                cell.descriptionView.text = record.descriptionString
                cell.warrantyStarts.text = dateFormatter.string(from: record.warrantyStarts! as Date)
                cell.warrantyEnds.text = dateFormatter.string(from: record.warrantyEnds! as Date)
                let recordImage = UIImage(data: record.itemImage as! Data)
                cell.warrantyImageView.image = recordImage
            } else {
                sections[indexPath.section].sort(by:{ $0.warrantyEnds?.compare($1.warrantyEnds as! Date) == .orderedAscending})
                let record = sections[indexPath.section][indexPath.row]
                cell.title.text = record.title
                cell.descriptionView.text = record.descriptionString
                cell.warrantyStarts.text = dateFormatter.string(from: record.warrantyStarts! as Date)
                cell.warrantyEnds.text = dateFormatter.string(from: record.warrantyEnds! as Date)
                let recordImage = UIImage(data: record.itemImage as! Data)
                cell.warrantyImageView.image = recordImage
            }
        } else {
            sections = [records, recentlyDeletedRecords, expiredRecords]
            if sortBySegmentControl.selectedSegmentIndex == 0 {
                sections[indexPath.section].sort(by:{ $0.dateCreated?.compare($1.dateCreated as! Date) == .orderedDescending})
                let record = sections[indexPath.section][indexPath.row]
                cell.title.text = record.title
                cell.descriptionView.text = record.descriptionString
                cell.warrantyStarts.text = dateFormatter.string(from: record.warrantyStarts! as Date)
                cell.warrantyEnds.text = dateFormatter.string(from: record.warrantyEnds! as Date)
                let recordImage = UIImage(data: record.itemImage as! Data)
                cell.warrantyImageView.image = recordImage
            } else {
                sections[indexPath.section].sort(by:{ $0.warrantyEnds?.compare($1.warrantyEnds as! Date) == .orderedAscending})
                let record = sections[indexPath.section][indexPath.row]
                cell.title.text = record.title
                cell.descriptionView.text = record.descriptionString
                cell.warrantyStarts.text = dateFormatter.string(from: record.warrantyStarts! as Date)
                cell.warrantyEnds.text = dateFormatter.string(from: record.warrantyEnds! as Date)
                let recordImage = UIImage(data: record.itemImage as! Data)
                cell.warrantyImageView.image = recordImage
            }

        }
        cell.warrantyImageView.contentMode = .scaleAspectFit
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchActive {
            sections = [filteredRecords, recentlyDeletedRecords, expiredRecords]
            return sections[section].count
        } else {
            sections = [records, recentlyDeletedRecords, expiredRecords]
            print(sections[section].count)
            return sections[section].count
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            warrantiesTableView.beginUpdates()
            
            if searchActive {
                sections = [filteredRecords, recentlyDeletedRecords, expiredRecords]
                let recordToRemove = sections[indexPath.section][indexPath.row]
                let index = records.index(of: recordToRemove)
                delete(record: sections[indexPath.section][indexPath.row])
                records.remove(at: index!)
            } else {
                sections = [records, recentlyDeletedRecords, expiredRecords]
                sections[1].insert(sections[indexPath.section][indexPath.row], at: 0)
                recentlyDeletedRecords = sections[1]
                delete(record: sections[indexPath.section][indexPath.row])
                sections[indexPath.section].remove(at: indexPath.row)
                records = sections[indexPath.section]
            }
            warrantiesTableView.deleteRows(at: [indexPath], with: .fade)
            let toIndexPath = IndexPath(row: 0, section: 1)
            warrantiesTableView.insertRows(at: [toIndexPath], with: .fade)
            
            warrantiesTableView.endUpdates()
        }
    }
    
    func delete(record: Record) {
        
        var fetchedRecordToDelete: Record!
        
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Record")
        fetchRequest.predicate = NSPredicate(format: "dateCreated = %@", record.dateCreated!)
        
        do {
            fetchedRecordToDelete = try managedContext.fetch(fetchRequest)[0] as! Record
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        if record.recentlyDeleted { // permenantly delete record
            
        } else { // set recentlyDeleted = true
            fetchedRecordToDelete.recentlyDeleted = true
            fetchedRecordToDelete.dateDeleted = Date() as NSDate?
            
            do {
                try managedContext.save()
            } catch {
                print("Could not save. \(error), \(error.localizedDescription)")
            }
        }
    }
    
    
    
    //MARK: Search bar delegate functions
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false;
        warrantiesTableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredRecords = []
        for record in records {
            let currentRecord = record
            for tag in currentRecord.tags! {
                let currentTag = tag as! Tag
                if ((currentRecord.title?.contains(searchText))! || (currentTag.tag?.contains(searchText))!) && !filteredRecords.contains(currentRecord) {
                    filteredRecords.append(currentRecord)
                }
            }
        }
        
        if (searchText == "") {
            searchActive = false;
        } else {
            searchActive = true;
        }
        warrantiesTableView.reloadData()
    }
    
    
    
    //MARK: Peek and Pop methods
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        guard let indexPath = warrantiesTableView.indexPathForRow(at: location),
            let cell = warrantiesTableView.cellForRow(at: indexPath) else {
            return nil
        }
        
        guard let detailViewController =
            storyboard?.instantiateViewController(
                withIdentifier: "DetailsViewController") as?
            DetailsViewController else {
            return nil
        }
        
        if searchActive {
            selectedRecord = filteredRecords[indexPath.row-1] 
        } else {
            selectedRecord = records[indexPath.row-1] 
        }
        
        detailViewController.record = selectedRecord
        detailViewController.preferredContentSize =
            CGSize(width: 0.0, height: 600)
        
        previewingContext.sourceRect = cell.frame
        
        return detailViewController
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
    
    // MARK: Prepare for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "toCellDetails") {
            if let nextViewController = segue.destination as? DetailsViewController {
                if (selectedRecord != nil) {
                    nextViewController.record = selectedRecord
                } else {
                    print("Selected Record was nil")
                }
            }
        }
    }
}

