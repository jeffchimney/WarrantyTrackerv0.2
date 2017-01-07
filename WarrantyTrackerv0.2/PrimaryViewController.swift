
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

class PrimaryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UIViewControllerPreviewingDelegate, UIScrollViewDelegate {
    
    let searchController = UISearchController(searchResultsController: nil)
    var searchActive = false
    var rectOfLastRow = CGRect()
    var lastCell: WarrantyTableViewCell!
    var originalSearchViewCenter = CGPoint(x:0, y:0) // both of these are set in view did load
    var originalTableViewCenter = CGPoint(x:0, y:0) //
    var hidingSearchView = false
    var refreshControl: UIRefreshControl!
    
    var backToTopButton: UIButton!

    //@IBOutlet weak var searchView: UIView!
    @IBOutlet weak var sortBySegmentControl: UISegmentedControl!
    @IBOutlet weak var warrantiesTableView: UITableView!
    @IBOutlet weak var archiveButton: UIBarButtonItem!
    let cellIdentifier = "WarrantyTableViewCell"
    var fetchedRecords: [NSManagedObject] = []
    var records: [Record] = []
    var filteredRecords: [Record] = []
    var sections: [[Record]] = [[]]
    var selectedRecord: Record!
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
        navigationController?.isToolbarHidden = true
        
        let defaults = UserDefaults.standard
        if (defaults.object(forKey: "FirstLaunch") == nil) {
            //go to sign up page
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "AccountQuestionViewController")
            
            self.present(vc, animated: true, completion: nil)
        } // otherwise, carry on as normal.
    }
    
    func handleRefresh(refreshControl: UIRefreshControl) {
        self.warrantiesTableView.reloadData()
        refreshControl.endRefreshing()
    }
    
    func configureButton()
    {
        backToTopButton = UIButton()
        backToTopButton.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        backToTopButton.layer.cornerRadius = 0.5 * backToTopButton.bounds.size.width
        backToTopButton.layer.borderColor = warrantiesTableView.tintColor.cgColor
        backToTopButton.layer.borderWidth = 2.0
        backToTopButton.clipsToBounds = true
        backToTopButton.setBackgroundImage(UIImage(named: "arrow"), for: .normal)
        backToTopButton.setBackgroundImage(UIImage(named: "arrow"), for: .selected)
        backToTopButton.center = CGPoint(x: warrantiesTableView.center.x, y: view.frame.height - 50)
        backToTopButton.alpha = 0
        backToTopButton.addTarget(self, action: #selector(backToTopButtonPressed(sender:)), for: .touchUpInside)
        self.view.addSubview(backToTopButton)
    }
    
    override func viewDidLayoutSubviews() {
        configureButton()
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
            let calendar = NSCalendar.current
            
            if record.recentlyDeleted {
                // Replace the hour (time) of both dates with 00:00
                let deletedDate = calendar.startOfDay(for: record.dateDeleted as! Date)
                let currentDate = calendar.startOfDay(for: Date())
                
                let components = calendar.dateComponents([.day], from: deletedDate, to: currentDate)
                
                if components.day! > 30 { // This will return the number of day(s) between dates
                    do {
                        managedContext.delete(record)
                        try managedContext.save()
                    } catch {
                        print("Record could not be deleted")
                    }
                }
            } else { // add to active records list
                // Replace the hour (time) of both dates with 00:00
                let expiryDate = calendar.startOfDay(for: record.warrantyEnds as! Date)
                let currentDate = calendar.startOfDay(for: Date())

                let components = calendar.dateComponents([.day], from: expiryDate, to: currentDate)

                if components.day! > 0 { // This will return the number of day(s) between dates
                    do {
                        record.expired = true
                        try managedContext.save()
                    } catch {
                        print("Record could not be deleted")
                    }
                } else {
                    records.append(record)
                }
            }
        }
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
    
//    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        return sectionHeaders[section]
//    }
    
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
            if sortBySegmentControl.selectedSegmentIndex == 0 {
                filteredRecords.sort(by:{ $0.dateCreated?.compare($1.dateCreated as! Date) == .orderedDescending})
                let record = filteredRecords[indexPath.row]
                cell.title.text = record.title
                //cell.descriptionView.text = record.descriptionString
                cell.warrantyStarts.text = dateFormatter.string(from: record.warrantyStarts! as Date)
                cell.warrantyEnds.text = dateFormatter.string(from: record.warrantyEnds! as Date)
                let recordImage = UIImage(data: record.itemImage as! Data)
                cell.warrantyImageView.image = recordImage
            } else {
                filteredRecords.sort(by:{ $0.warrantyEnds?.compare($1.warrantyEnds as! Date) == .orderedAscending})
                let record = filteredRecords[indexPath.row]
                cell.title.text = record.title
                //cell.descriptionView.text = record.descriptionString
                cell.warrantyStarts.text = dateFormatter.string(from: record.warrantyStarts! as Date)
                cell.warrantyEnds.text = dateFormatter.string(from: record.warrantyEnds! as Date)
                let recordImage = UIImage(data: record.itemImage as! Data)
                cell.warrantyImageView.image = recordImage
            }
        } else {
            if sortBySegmentControl.selectedSegmentIndex == 0 {
                records.sort(by:{ $0.dateCreated?.compare($1.dateCreated as! Date) == .orderedDescending})
                let record = records[indexPath.row]
                cell.title.text = record.title
                //cell.descriptionView.text = record.descriptionString
                cell.warrantyStarts.text = dateFormatter.string(from: record.warrantyStarts! as Date)
                cell.warrantyEnds.text = dateFormatter.string(from: record.warrantyEnds! as Date)
                let recordImage = UIImage(data: record.itemImage as! Data)
                cell.warrantyImageView.image = recordImage
            } else {
                records.sort(by:{ $0.warrantyEnds?.compare($1.warrantyEnds as! Date) == .orderedAscending})
                let record = records[indexPath.row]
                cell.title.text = record.title
                //cell.descriptionView.text = record.descriptionString
                cell.warrantyStarts.text = dateFormatter.string(from: record.warrantyStarts! as Date)
                cell.warrantyEnds.text = dateFormatter.string(from: record.warrantyEnds! as Date)
                let recordImage = UIImage(data: record.itemImage as! Data)
                cell.warrantyImageView.image = recordImage
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
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if (scrollView.contentOffset.y <= 0 && self.backToTopButton.alpha != 0) {
            UIView.animate(withDuration: 0.5, animations: {
                self.backToTopButton.alpha = 0
            })
        } else if (scrollView.contentOffset.y > 0 && self.backToTopButton.alpha == 0) {
            UIView.animate(withDuration: 0.5, animations: {
                self.backToTopButton.alpha = 0.5
            })
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
    
    func backToTopButtonPressed(sender: UIButton) {
        //let indexPath = IndexPath(row: 0, section: 0)
        //warrantiesTableView.scrollToRow(at: indexPath, at: UITableViewScrollPosition.top, animated: true)
        UIView.animate(withDuration: 0.2, animations: {
            self.warrantiesTableView.contentOffset.y = 0
        })
    }
    
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
                withIdentifier: "DetailsViewController") as?
            DetailsViewController else {
            return nil
        }
        
        if searchActive {
            selectedRecord = filteredRecords[indexPath.row]
        } else {
            selectedRecord = records[indexPath.row]
        }
        
        detailViewController.record = selectedRecord
        detailViewController.preferredContentSize =
            CGSize(width: 0.0, height: 500)
        
        previewingContext.sourceRect = cell.frame
        
        return detailViewController
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
    
    @IBAction func unwindToInitialController(segue: UIStoryboardSegue){}
    
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

