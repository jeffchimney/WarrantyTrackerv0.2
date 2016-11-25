
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

    @IBOutlet weak var warrantiesTableView: UITableView!
    let cellIdentifier = "WarrantyTableViewCell"
    var records: [NSManagedObject] = []
    var filteredRecords: [NSManagedObject] = []
    var selectedRecord: Record!
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.warrantiesTableView.delegate = self
        self.warrantiesTableView.dataSource = self
        
        //get your object from CoreData
        
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
            records = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        //get your object from CoreData
        
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1 // maybe 2 if we want a separate section for expired warranties
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if searchActive {
            selectedRecord = filteredRecords[indexPath.row] as! Record
            performSegue(withIdentifier: "toCellDetails", sender: self)
        } else {
            selectedRecord = records[indexPath.row] as! Record
            performSegue(withIdentifier: "toCellDetails", sender: self)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! WarrantyTableViewCell
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        if searchActive {
            let record = filteredRecords[indexPath.row] as! Record
            cell.title.text = record.title
            cell.descriptionView.text = record.descriptionString
            cell.warrantyStarts.text = dateFormatter.string(from: record.warrantyStarts! as Date)
            cell.warrantyEnds.text = dateFormatter.string(from: record.warrantyEnds! as Date)
            let recordImage = UIImage(data: record.itemImage as! Data)
            cell.warrantyImageView.image = recordImage
        } else {
            let record = records[indexPath.row] as! Record
            cell.title.text = record.title
            cell.descriptionView.text = record.descriptionString
            cell.warrantyStarts.text = dateFormatter.string(from: record.warrantyStarts! as Date)
            cell.warrantyEnds.text = dateFormatter.string(from: record.warrantyEnds! as Date)
            let recordImage = UIImage(data: record.itemImage as! Data)
            cell.warrantyImageView.image = recordImage
        }
        cell.warrantyImageView.contentMode = .scaleAspectFit
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchActive {
            return filteredRecords.count
        } else {
            return records.count
        }
    }
    
    // handle edit and deletes on tableview cells
//    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
//        if editingStyle == .delete {
//            if searchActive {
//                let alert = UIAlertController(title: "Are you sure?", message: "Deleting this record will remove all associated data.", preferredStyle: UIAlertControllerStyle.alert)
//                alert.addAction(UIAlertAction(title: "Delete", style: UIAlertActionStyle.default, handler: {(action:UIAlertAction!) in
//                    let selectedRecord = self.filteredRecords[indexPath.row] as! Record
//                    self.filteredRecords.remove(at: indexPath.row)
//                    tableView.deleteRows(at: [indexPath], with: .fade)
//                    self.delete(withDateTime: selectedRecord.dateCreated!)
//                    tableView.reloadData()
//                }))
//                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: {(action:UIAlertAction!) in print("you have pressed the Cancel button")
//                }))
//                self.present(alert, animated: true, completion: nil)
//            } else {
//                let alert = UIAlertController(title: "Are you sure?", message: "Deleting this record will remove all associated data.", preferredStyle: UIAlertControllerStyle.alert)
//                alert.addAction(UIAlertAction(title: "Delete", style: UIAlertActionStyle.default, handler: {(action:UIAlertAction!) in
//                    let selectedRecord = self.records[indexPath.row] as! Record
//                    self.records.remove(at: indexPath.row)
//                    tableView.deleteRows(at: [indexPath], with: .fade)
//                    self.delete(withDateTime: selectedRecord.dateCreated!)
//                    tableView.reloadData()
//                }))
//                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: {(action:UIAlertAction!) in print("you have pressed the Cancel button")
//                }))
//                self.present(alert, animated: true, completion: nil)
//            }
//        }
//    }
    
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
            let currentRecord = record as! Record
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
                return nil }
        
        guard let detailViewController =
            storyboard?.instantiateViewController(
                withIdentifier: "DetailsViewController") as?
            DetailsViewController else { return nil }
        
        if searchActive {
            selectedRecord = filteredRecords[indexPath.row-1] as! Record
        } else {
            selectedRecord = records[indexPath.row-1] as! Record
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

