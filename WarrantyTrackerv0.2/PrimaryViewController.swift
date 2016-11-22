
//
//  SecondViewController.swift
//  WarrantyTrackerv0.2
//
//  Created by Jeff Chimney on 2016-11-01.
//  Copyright © 2016 Jeff Chimney. All rights reserved.
//

import UIKit
import CoreData

class PrimaryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    let searchController = UISearchController(searchResultsController: nil)
    var searchActive = false

    @IBOutlet weak var warrantiesTableView: UITableView!
    let cellIdentifier = "WarrantyTableViewCell"
    var records: [NSManagedObject] = []
    var filteredRecords: [NSManagedObject] = []
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
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchActive {
            return filteredRecords.count
        } else {
            return records.count
        }
    }
    
    //MARK: Search bar delegate functions
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchActive = true;
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
                    print("appending match")
                }
            }
        }
        
        if(filteredRecords.count == 0){
            searchActive = false;
        } else {
            searchActive = true;
        }
        print("Changed")
        warrantiesTableView.reloadData()
    }
}

