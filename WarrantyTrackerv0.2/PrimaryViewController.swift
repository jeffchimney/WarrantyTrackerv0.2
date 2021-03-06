
//
//  SecondViewController.swift
//  WarrantyTrackerv0.2
//
//  Created by Jeff Chimney on 2016-11-01.
//  Copyright © 2016 Jeff Chimney. All rights reserved.
//

import UIKit
import CoreData
import CloudKit

public protocol ReloadTableViewDelegate: class {
    func reloadLastControllerTableView()
}

class PrimaryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UIViewControllerPreviewingDelegate, UIScrollViewDelegate, ReloadTableViewDelegate {
    
    var managedContext: NSManagedObjectContext?
    let searchController = UISearchController(searchResultsController: nil)
    var searchActive = false
    var rectOfLastRow = CGRect()
    var lastCell: WarrantyTableViewCell!
    var originalSearchViewCenter = CGPoint(x:0, y:0) // both of these are set in view did load
    var originalTableViewCenter = CGPoint(x:0, y:0) //
    var hidingSearchView = false
    var refreshControl: UIRefreshControl!
    
    //var backToTopButton: UIButton!

    //@IBOutlet weak var searchView: UIView!
    @IBOutlet weak var searchButton: UIBarButtonItem!
    @IBOutlet weak var sortBySegmentControl: UISegmentedControl!
    @IBOutlet weak var warrantiesTableView: UITableView!
    @IBOutlet weak var archiveButton: UIBarButtonItem!
    let cellIdentifier = "WarrantyTableViewCell"
    var records: [Record] = []
    var filteredRecords: [Record] = []
    var ckRecords: [CKRecord] = []
    var cdImagesForRecord: [Image] = []
    var ckImagesForRecord: [CKRecord] = []
    var cdNotesForRecord: [Note] = []
    var ckNotesForRecord: [CKRecord] = []
    var sections: [[Record]] = [[]]
    var selectedRecord: Record!
    let defaults = UserDefaults.standard
    
    let generator = UIImpactFeedbackGenerator(style: .medium)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        managedContext = appDelegate.persistentContainer.viewContext

        self.warrantiesTableView.delegate = self
        self.warrantiesTableView.dataSource = self
        
        refreshControl = UIRefreshControl()
        refreshControl.backgroundColor = UIColor.white
        refreshControl.addTarget(self, action: #selector(handleRefresh(refreshControl:)), for: UIControlEvents.valueChanged)
        warrantiesTableView.addSubview(refreshControl)
        
        // sorted by recent by default
        sortBySegmentControl.selectedSegmentIndex = 0
        
        self.warrantiesTableView.reloadData()
        
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.searchBarStyle = .default
        searchController.searchBar.backgroundColor = warrantiesTableView.tintColor
        definesPresentationContext = true
        
        searchController.searchBar.delegate = self
        
        // register for previewing with 3d touch
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: view)
        } else {
            print("3D Touch Not Available")
        }
        warrantiesTableView.tableHeaderView = searchController.searchBar
        
        let defaults = UserDefaults.standard
        if (defaults.object(forKey: "FirstLaunch") == nil) {
            //go to sign up page
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "AccountQuestionViewController")
            
            self.present(vc, animated: true, completion: nil)
        } // otherwise, carry on as normal.
        
        NotificationCenter.default.addObserver(self, selector: #selector(statusManager), name: .flagsChanged, object: Network.reachability)
        
        // fonts
        let defaultFont = UIFont(name: "Kohinoor Bangla", size: 15)!
        let attributes = [
            NSFontAttributeName: defaultFont
        ]
        let defaultBarButtonFont = UIFont(name: "Kohinoor Bangla", size: 17)!
        let barButtonAttributes = [
            NSFontAttributeName: defaultBarButtonFont
        ]
        
        sortBySegmentControl.setTitleTextAttributes(attributes, for: .normal)
        searchButton.setTitleTextAttributes(barButtonAttributes, for: .normal)
        
         let textFieldInsideSearchBar = searchController.searchBar.value(forKey: "searchField") as! UITextField
        textFieldInsideSearchBar.defaultTextAttributes = attributes
        
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: "Kohinoor Telugu", size: 18)!]
        
        updateUserInterface()
        handleRefresh(refreshControl: refreshControl)
    }
    
    func handleRefresh(refreshControl: UIRefreshControl) {
        // check if the user is signed in, if not then there is nothing to refresh.
        if (UserDefaultsHelper.isSignedIn()) {
            // check what the current connection is.  If wifi, refresh.  If data, and sync by data is enabled, refresh.  Otherwise don't.
            let conn = UserDefaultsHelper.currentConnection()
            if (conn == "wifi" || (conn == "data" && UserDefaultsHelper.canSyncUsingData())) {
                // coredata
                let recordEntity = NSEntityDescription.entity(forEntityName: "Record", in: managedContext!)!
                
                let fetchRequest =
                    NSFetchRequest<NSManagedObject>(entityName: "Account")
                
                var accountRecords: [NSManagedObject] = []
                do {
                    accountRecords = try managedContext!.fetch(fetchRequest)
                } catch let error as NSError {
                    print("Could not fetch. \(error), \(error.userInfo)")
                }
                let account = accountRecords[0] as! Account
                
                var cdRecords = CoreDataHelper.fetchAllRecords(in: managedContext!) // loadAssociatedCDRecords()
                var cdRecordIDs: [String] = []
                for record in cdRecords {
                    print(record.recordID! + " " + record.title!)
                    cdRecordIDs.append(record.recordID!)
                }
                
                // cloudkit
                let publicDatabase:CKDatabase = CKContainer.default().publicCloudDatabase
                let predicate = NSPredicate(format: "AssociatedAccount = %@", CKRecordID(recordName: account.id!))
                let query = CKQuery(recordType: "Records", predicate: predicate)
                
                publicDatabase.perform(query, inZoneWith: nil, completionHandler: { (results, error) in
                    if error != nil {
                        DispatchQueue.main.async {
                            print(error.debugDescription)
                            self.refreshControl.endRefreshing()
                        }
                        return
                    } else {
                        for result in results! {
                            // if record id is in coredata already, sync data to that record
                            if cdRecordIDs.contains(result.recordID.recordName) {
                                let recordIndex = cdRecordIDs.index(of: result.recordID.recordName)
                                let recordMatch = cdRecords[recordIndex!]
                                
                                // check if cloud was synced before local storage
                                let cloudSynced = result.value(forKey: "lastSynced") as! Date
                                let localSynced = (recordMatch.lastUpdated ?? Date().addingTimeInterval(-TimeInterval.greatestFiniteMagnitude) as NSDate) as Date
                                DispatchQueue.main.async {
                                    print(localSynced)
                                }
                                if cloudSynced > localSynced {
                                    // sync from cloud to local and pop from cdRecords and cdRecordIDs arrays
                                    DispatchQueue.main.async {
                                        print("Syncing from cloud to local")
                                    }
                                    let record = recordMatch
                                    record.dateCreated = result.value(forKey: "dateCreated") as! NSDate?
                                    record.dateDeleted = result.value(forKey: "dateDeleted") as! NSDate?
                                    record.daysBeforeReminder = result.value(forKey: "daysBeforeReminder") as! Int32
                                    record.descriptionString = result.value(forKey: "descriptionString") as! String?
                                    record.eventIdentifier = result.value(forKey: "eventIdentifier") as! String?
                                    record.title = result.value(forKey: "title") as! String?
                                    record.warrantyStarts = result.value(forKey: "warrantyStarts") as! NSDate?
                                    record.warrantyEnds = result.value(forKey: "warrantyEnds") as! NSDate?
                                    DispatchQueue.main.async {
                                        print("Assigned simple values")
                                    }
                                    // CKAssets need to be converted to NSData
                                    //let itemImage = result.value(forKey: "itemData") as! CKAsset
                                    //record.itemImage = NSData(contentsOf: itemImage.fileURL)
                                    //////let receiptImage = result.value(forKey: "receiptData") as! CKAsset
                                    //record.receiptImage = NSData(contentsOf: receiptImage.fileURL)
                                    // Bools stored as ints on CK.  Need to be converted
                                    let recentlyDeleted = result.value(forKey: "recentlyDeleted") as! Int64
                                    if recentlyDeleted == 0 {
                                        record.recentlyDeleted = false
                                    } else {
                                        record.recentlyDeleted = true
                                    }
                                    let expired = result.value(forKey: "expired") as! Int64
                                    if expired == 0 {
                                        record.expired = false
                                    } else {
                                        record.expired = true
                                    }
                                    let hasWarranty = result.value(forKey: "hasWarranty") as! Int64
                                    if hasWarranty == 0 {
                                        record.hasWarranty = false
                                    } else {
                                        record.hasWarranty = true
                                    }
                                    record.lastUpdated = Date() as NSDate?
                                    record.recordID = result.recordID.recordName
                                    
                                    DispatchQueue.main.async {
                                        print("Assigned assets and other values to " + record.recordID!)
                                    }
                                    
                                    // remove updated record from record lists so that once finished, the remainder
                                    // (those not existing on the cloud) can be synced to the cloud.
                                    cdRecords.remove(at: recordIndex!)
                                    cdRecordIDs.remove(at: recordIndex!)
                                }
                                
                                // sync notes and images associated with this record to coredata if they aren't already there
                                CoreDataHelper.importImagesFromCloudKit(associatedWith: recordMatch, in: self.managedContext!)
                                CoreDataHelper.importNotesFromCloudKit(associatedWith: recordMatch, in: self.managedContext!)
                                
                                // sync any images that havent been synced to the cloud yet
                                CloudKitHelper.syncImagesToCloudKit(associatedWith: recordMatch, in: self.managedContext!)
                                // ^ this should be happening automatically on image creation now.
                                
                            } else { // create new record from data in cloud
                                let record = NSManagedObject(entity: recordEntity, insertInto: self.managedContext!) as! Record
                                record.dateCreated = result.value(forKey: "dateCreated") as! NSDate?
                                record.dateDeleted = result.value(forKey: "dateDeleted") as! NSDate?
                                record.daysBeforeReminder = result.value(forKey: "daysBeforeReminder") as! Int32
                                record.descriptionString = result.value(forKey: "descriptionString") as! String?
                                record.eventIdentifier = result.value(forKey: "eventIdentifier") as! String?
                                record.title = result.value(forKey: "title") as! String?
                                record.warrantyStarts = result.value(forKey: "warrantyStarts") as! NSDate?
                                record.warrantyEnds = result.value(forKey: "warrantyEnds") as! NSDate?
                                // CKAssets need to be converted to NSData
                                //let itemImage = result.value(forKey: "itemData") as! CKAsset
                                //record.itemImage = NSData(contentsOf: itemImage.fileURL)
                                //let receiptImage = result.value(forKey: "receiptData") as! CKAsset
                                //record.receiptImage = NSData(contentsOf: receiptImage.fileURL)
                                // Bools stored as ints on CK.  Need to be converted
                                let recentlyDeleted = result.value(forKey: "recentlyDeleted") as! Int64
                                if recentlyDeleted == 0 {
                                    record.recentlyDeleted = false
                                } else {
                                    record.recentlyDeleted = true
                                }
                                let expired = result.value(forKey: "expired") as! Int64
                                if expired == 0 {
                                    record.expired = false
                                } else {
                                    record.expired = true
                                }
                                let hasWarranty = result.value(forKey: "hasWarranty") as! Int64
                                if hasWarranty == 0 {
                                    record.hasWarranty = false
                                } else {
                                    record.hasWarranty = true
                                }
                                record.lastUpdated = Date() as NSDate?
                                record.recordID = result.recordID.recordName
                            }
                            // Check each note and image in the cloud to check if it has been deleted
                            self.removeRecentlyDeletedImagesAndNotes(associatedWith: result.recordID, in: self.managedContext!)
                        }
                        // Whatever remains in the cdRecords array, sync to cloud and set lastSynced to current time
                        // this should already be up to date because everything is being synced on creation.
//                        for eachRecord in cdRecords {
//                            CloudKitHelper.importCDRecord(cdRecord: eachRecord, context: self.managedContext!)
//                        }
//                        DispatchQueue.main.async {
//                            print("Just about to save")
//                        }
                        CoreDataHelper.save(context: self.managedContext!)
                    }
                    DispatchQueue.main.async {
                        self.refreshControl.endRefreshing()
                        self.warrantiesTableView.reloadData()
                    }
                })
            } else {
                // let user know they don't have a connection
                
            }
        }
    }
    
    func removeRecentlyDeletedImagesAndNotes(associatedWith: CKRecordID, in context: NSManagedObjectContext) {
        let publicDatabase:CKDatabase = CKContainer.default().publicCloudDatabase
        
        // remove any images that have been deleted recently
        let predicate = NSPredicate(format: "associatedRecord = %@", CKReference(record: CKRecord(recordType: "Images", recordID: associatedWith), action: CKReferenceAction.deleteSelf))
        let query = CKQuery(recordType: "Images", predicate: predicate)
        
        publicDatabase.perform(query, inZoneWith: nil, completionHandler: { (results, error) in
            if error != nil {
                print("Error pulling from CloudKit")
            } else {
                if results != nil {
                    for result in results! {
                        if result.value(forKey: "recentlyDeleted") as! Int != 0 { // if recently deleted
                            DispatchQueue.main.async {
                                //print("CK record to delete: \(result.recordID.recordName)")
                            }
                            // find in coredata and delete
                            let deletedRecord: Image? = CoreDataHelper.fetchImage(with: result.recordID.recordName, in: context)
                            
                            if deletedRecord != nil {
                                CoreDataHelper.delete(image: deletedRecord!, in: context)
                                
                                DispatchQueue.main.async {
                                    print("Successfully deleted)")
                                }
                            }
                        }
                    }
                }
            }
        })
        
        // remove any notes that have been deleted recently
        let notesPredicate = NSPredicate(format: "associatedRecord = %@", CKReference(record: CKRecord(recordType: "Notes", recordID: associatedWith), action: CKReferenceAction.deleteSelf))
        let notesQuery = CKQuery(recordType: "Notes", predicate: notesPredicate)
        
        publicDatabase.perform(notesQuery, inZoneWith: nil, completionHandler: { (results, error) in
            if error != nil {
                print("Error pulling from CloudKit")
            } else {
                if results != nil {
                    for result in results! {
                        if result.value(forKey: "recentlyDeleted") as! Int != 0 { // if recently deleted
                            DispatchQueue.main.async {
                                //print("CK record to delete: \(result.recordID.recordName)")
                            }
                            // find in coredata and delete
                            let deletedNote: Note? = CoreDataHelper.fetchNote(with: result.recordID.recordName, in: context)
                            
                            if deletedNote != nil {
                                CoreDataHelper.delete(note: deletedNote!, in: context)
                                
                                DispatchQueue.main.async {
                                    print("Successfully deleted)")
                                }
                            }
                        }
                    }
                }
            }
        })
    }
    
    override func viewDidLayoutSubviews() {
        //configureButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let fetchedRecords = CoreDataHelper.fetchAllRecords(in: managedContext!)
        checkExpiryAndDeletedDates(for: fetchedRecords, context: managedContext!)
        
        navigationController?.isToolbarHidden = false
        navigationController?.view.clipsToBounds = true
        navigationController?.view.layer.masksToBounds = true
        navigationController?.view.layer.cornerRadius = 8
        
        self.warrantiesTableView.reloadData()
    }
    
    @IBAction func selectedSegmentChanged(_ sender: Any) {
        self.warrantiesTableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        generator.impactOccurred()
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
            if sortBySegmentControl.selectedSegmentIndex == 0 {
                filteredRecords.sort(by:{ $0.dateCreated?.compare($1.dateCreated! as Date) == .orderedDescending})
                let record = filteredRecords[indexPath.row]
                cell.title.text = record.title
                //cell.descriptionView.text = record.descriptionString
                cell.warrantyStarts.text = dateFormatter.string(from: record.warrantyStarts! as Date)
                if !record.hasWarranty {
                    cell.warrantyEnds.text = dateFormatter.string(from: record.warrantyEnds! as Date)
                } else {
                    cell.warrantyEnds.text = "∞"
                }
                let fetchedImages = CoreDataHelper.fetchImages(for: record, in: managedContext!)
                if fetchedImages.count > 0 {
                    let recordImage = fetchedImages[0]
                    cell.warrantyImageView.image = UIImage(data: recordImage.image! as Data)
                } else {
                    cell.warrantyImageView.image = UIImage(named: "loadingIndicator")
                }
            } else {
                filteredRecords.sort(by:{ $0.warrantyEnds?.compare($1.warrantyEnds! as Date) == .orderedAscending})
                let record = filteredRecords[indexPath.row]
                cell.title.text = record.title
                //cell.descriptionView.text = record.descriptionString
                cell.warrantyStarts.text = dateFormatter.string(from: record.warrantyStarts! as Date)
                if !record.hasWarranty {
                    cell.warrantyEnds.text = dateFormatter.string(from: record.warrantyEnds! as Date)
                } else {
                    cell.warrantyEnds.text = "∞"
                }
                let fetchedImages = CoreDataHelper.fetchImages(for: record, in: managedContext!)
                if fetchedImages.count > 0 {
                    let recordImage = fetchedImages[0]
                    cell.warrantyImageView.image = UIImage(data: recordImage.image! as Data)
                } else {
                    cell.warrantyImageView.image = UIImage(named: "loadingIndicator")
                }
            }
        } else {
            if sortBySegmentControl.selectedSegmentIndex == 0 {
                records.sort(by:{ $0.dateCreated?.compare($1.dateCreated! as Date) == .orderedDescending})
                let record = records[indexPath.row]
                cell.title.text = record.title
                //cell.descriptionView.text = record.descriptionString
                cell.warrantyStarts.text = dateFormatter.string(from: record.warrantyStarts! as Date)
                if !record.hasWarranty {
                    cell.warrantyEnds.text = dateFormatter.string(from: record.warrantyEnds! as Date)
                } else {
                    cell.warrantyEnds.text = "∞"
                }
                let fetchedImages = CoreDataHelper.fetchImages(for: record, in: managedContext!)
                if fetchedImages.count > 0 {
                    let recordImage = fetchedImages[0]
                    cell.warrantyImageView.image = UIImage(data: recordImage.image! as Data)
                } else {
                    cell.warrantyImageView.image = UIImage(named: "loadingIndicator")
                }
            } else {
                records.sort(by:{ $0.warrantyEnds?.compare($1.warrantyEnds! as Date) == .orderedAscending})
                let record = records[indexPath.row]
                cell.title.text = record.title
                //cell.descriptionView.text = record.descriptionString
                cell.warrantyStarts.text = dateFormatter.string(from: record.warrantyStarts! as Date)
                if !record.hasWarranty {
                    cell.warrantyEnds.text = dateFormatter.string(from: record.warrantyEnds! as Date)
                } else {
                    cell.warrantyEnds.text = "∞"
                }
                let fetchedImages = CoreDataHelper.fetchImages(for: record, in: managedContext!)
                if fetchedImages.count > 0 {
                    let recordImage = fetchedImages[0]
                    cell.warrantyImageView.image = UIImage(data: recordImage.image! as Data)
                } else {
                    cell.warrantyImageView.image = UIImage(named: "loadingIndicator")
                }
            }
            
        }
        cell.warrantyImageView.contentMode = .scaleAspectFit
        cell.title.textColor = cell.tintColor
        cell.backgroundColor = UIColor(colorLiteralRed: 189, green: 195, blue: 201, alpha: 1.0)
        
        lastCell = cell
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchActive {
            return filteredRecords.count
        } else {
            return records.count
        }
    }
    
    func reloadLastControllerTableView() {
        DispatchQueue.main.async() {
            let fetchedRecords = CoreDataHelper.fetchAllRecords(in: self.managedContext!)
            self.checkExpiryAndDeletedDates(for: fetchedRecords, context: self.managedContext!)
            self.warrantiesTableView.reloadData()
        }
    }
    
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        
//        if (scrollView.contentOffset.y <= 0 && self.backToTopButton.alpha != 0) {
//            UIView.animate(withDuration: 0.5, animations: {
//                self.backToTopButton.alpha = 0
//            })
//        } else if (scrollView.contentOffset.y > 0 && self.backToTopButton.alpha == 0) {
//            UIView.animate(withDuration: 0.5, animations: {
//                self.backToTopButton.alpha = 0.5
//            })
//        }
//        
//    }
    
    func checkExpiryAndDeletedDates(for recordsArray: [Record], context: NSManagedObjectContext) {
        records = []
        for eachRecord in recordsArray {
            let calendar = NSCalendar.current
            if eachRecord.recentlyDeleted {
                // Replace the hour (time) of both dates with 00:00
                let deletedDate = calendar.startOfDay(for: eachRecord.dateDeleted! as Date)
                let currentDate = calendar.startOfDay(for: Date())
                
                let components = calendar.dateComponents([.day], from: deletedDate, to: currentDate)
                
                if components.day! > 30 { // This will return the number of day(s) between dates
                    do {
                        context.delete(eachRecord)
                        try context.save()
                    } catch {
                        print("Record could not be deleted")
                    }
                }
            } else { // add to active records list
                // Replace the hour (time) of both dates with 00:00
                let expiryDate = calendar.startOfDay(for: eachRecord.warrantyEnds! as Date)
                let currentDate = calendar.startOfDay(for: Date())
                
                let components = calendar.dateComponents([.day], from: expiryDate, to: currentDate)
                
                if components.day! > 0 { // This will return the number of day(s) between dates
                    do {
                        eachRecord.expired = true
                        try context.save()
                    } catch {
                        print("Record could not be deleted")
                    }
                } else {
                    records.append(eachRecord)
                }
            }
        }
    }
    
    func getRecordsFromCloudKit() {
        let defaults = UserDefaults.standard
        let username = defaults.string(forKey: "username")
        let password = defaults.string(forKey: "password")
        
        if username != nil { // user is logged in
            let publicDatabase:CKDatabase = CKContainer.default().publicCloudDatabase
            let predicate = NSPredicate(format: "username = %@ AND password = %@", username!, password!)
            let query = CKQuery(recordType: "Accounts", predicate: predicate)
            
            var accountRecord = CKRecord(recordType: "Accounts")
            publicDatabase.perform(query, inZoneWith: nil, completionHandler: { (results, error) in
                if error != nil {
                    print("Error pulling from CloudKit")
                } else {
                    if (results?.count)! > 0 { // a record matching their username and password has been retrieved
                        accountRecord = (results?[0])!
                        
                        let recordsPredicate = NSPredicate(format: "AssociatedAccount = %@", accountRecord.recordID)
                        let recordsQuery = CKQuery(recordType: "Records", predicate: recordsPredicate)
                        publicDatabase.perform(recordsQuery, inZoneWith: nil, completionHandler: { (results, error) in
                            if error != nil {
                                print("Error retrieving records from cloudkit")
                            } else {
                                if (results?.count)! > 0 {
                                    // compare with core data records JEFF
                                }
                            }
                        })
                    }
                }
            })
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
            if (currentRecord.title?.lowercased().contains(searchText.lowercased()))! && !filteredRecords.contains(currentRecord) {
                filteredRecords.append(currentRecord)
            }
        }
        
        if (searchText == "") {
            searchActive = false;
        } else {
            searchActive = true;
        }
        warrantiesTableView.reloadData()
    }
    
//    func backToTopButtonPressed(sender: UIButton) {
//        //let indexPath = IndexPath(row: 0, section: 0)
//        //warrantiesTableView.scrollToRow(at: indexPath, at: UITableViewScrollPosition.top, animated: true)
//        UIView.animate(withDuration: 0.2, animations: {
//            self.warrantiesTableView.contentOffset.y = 0
//        })
//    }
    
    //MARK: Peek and Pop methods
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        // convert point from position in self.view to position in warrantiesTableView
        let cellPosition = warrantiesTableView.convert(location, from: self.view)
        
        guard let indexPath = warrantiesTableView.indexPathForRow(at: cellPosition),
            let cell = warrantiesTableView.cellForRow(at: indexPath) else {
            return nil
        }
        
        guard let detailViewController =
            storyboard?.instantiateViewController(
                withIdentifier: "DetailsTableViewController") as?
            DetailsTableViewController else {
            return nil
        }
        
        if searchActive {
            selectedRecord = filteredRecords[indexPath.row]
        } else {
            selectedRecord = records[indexPath.row]
        }
        
        detailViewController.reloadDelegate = self
        detailViewController.record = selectedRecord
        detailViewController.preferredContentSize =
            CGSize(width: 0.0, height: 500)
        
        previewingContext.sourceRect = view.convert(cell.frame, from: warrantiesTableView)
        
        return detailViewController
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
    
    @IBAction func unwindToInitialController(segue: UIStoryboardSegue){}
    
    // MARK: Prepare for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "toCellDetails") {
            if let nextViewController = segue.destination as? DetailsTableViewController {
                if (selectedRecord != nil) {
                    nextViewController.record = selectedRecord
                } else {
                    print("Selected Record was nil")
                }
            }
        }
    }
    
    //MARK: Network Connectivity Tests
    func updateUserInterface() {
        guard let status = Network.reachability?.status else { return }
        switch status {
        case .unreachable:
            defaults.set("unreachable", forKey: "connection")
        case .wifi:
            defaults.set("wifi", forKey: "connection")
            syncEverything()
            
        case .wwan:
            defaults.set("data", forKey: "connection")
            if UserDefaultsHelper.canSyncUsingData() {
                syncEverything() // there should only be anything in the queued array if the user is just coming out of an area of no service.
            }
        }
        print("Reachability Summary")
        print("Status:", status)
        print("HostName:", Network.reachability?.hostname ?? "nil")
        print("Reachable:", Network.reachability?.isReachable ?? "nil")
        print("Wifi:", Network.reachability?.isReachableViaWiFi ?? "nil")
    }
    func statusManager(_ notification: NSNotification) {
        if UserDefaultsHelper.isSignedIn() {
            updateUserInterface()
        }
    }
    
    func syncEverything() {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let queuedRecords = UserDefaultsHelper.getQueuedChanges()
        let queuedRecordsToDelete = UserDefaultsHelper.getQueuedToDelete()
        
        if queuedRecords != nil {
            if (queuedRecords?.count)! > 0 {
                for recordID in queuedRecords! {
                    
                    let publicDatabase:CKDatabase = CKContainer.default().publicCloudDatabase
                    publicDatabase.fetch(withRecordID: CKRecordID(recordName: recordID), completionHandler: ({record, error in
                        let fetchedRecord = CoreDataHelper.fetchRecord(with: recordID, in: managedContext) as Record
                        if let err = error {
                            DispatchQueue.main.async() {
                                print(err.localizedDescription)
                                print("Syncing as new record to cloud.")
                            }
                            // couldn't find record, save in cloud as new record
                            CloudKitHelper.importCDRecord(cdRecord: fetchedRecord, context: managedContext)
                        } else { // found record, update it in cloud
                            CloudKitHelper.updateRecordInCloudKit(cdRecord: fetchedRecord, context: managedContext)
                        }
                    }))
                }
                UserDefaultsHelper.setQueueToEmpty()
            }
        }
        
        if queuedRecordsToDelete != nil {
            if (queuedRecordsToDelete?.count)! > 0 {
                for recordID in queuedRecordsToDelete! {
                    
                    let publicDatabase:CKDatabase = CKContainer.default().publicCloudDatabase
                    publicDatabase.delete(withRecordID: CKRecordID(recordName: recordID), completionHandler: ({record, error in
                        if let err = error {
                            DispatchQueue.main.async() {
                                print(err.localizedDescription)
                                print("Syncing as new record to cloud.")
                            }
                            // couldn't find record, save in cloud as new record
                        } else { // found record, update it in cloud
                            
                        }
                    }))
                }
                UserDefaultsHelper.setQueueToEmpty()
            }
        }
    }
    
    func refresh() {
        
    }
}

