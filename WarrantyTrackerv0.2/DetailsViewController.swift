//
//  DetailsViewController.swift
//  WarrantyTrackerv0.2
//
//  Created by Jeff Chimney on 2016-11-24.
//  Copyright © 2016 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class DetailsViewController: UIViewController, UIViewControllerPreviewingDelegate {

    // variables passed from last view
    var record: Record!
    //
    
    @IBOutlet weak var navBar: UINavigationItem!
    @IBOutlet weak var itemImageView: UIImageView!
    @IBOutlet weak var receiptImageView: UIImageView!
    @IBOutlet weak var startDateLabel: UILabel!
    @IBOutlet weak var endDateLabel: UILabel!
    @IBOutlet weak var descriptionView: UITextView!
    @IBOutlet weak var daysBeforeLabel: UILabel!
    @IBOutlet weak var alertDateLabel: UILabel!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    
    var isEditingRecord = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        itemImageView.contentMode = .scaleAspectFit
        receiptImageView.contentMode = .scaleAspectFit
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        navBar.title = record.title!
        itemImageView.image = UIImage(data: record.itemImage as! Data)
        receiptImageView.image = UIImage(data: record.receiptImage as! Data)
        startDateLabel.text = dateFormatter.string(from: record.warrantyStarts as! Date)
        endDateLabel.text = dateFormatter.string(from: record.warrantyEnds as! Date)
        descriptionView.text = record.descriptionString
        daysBeforeLabel.text = String(record.weeksBeforeReminder) + " weeks before end date:"
        
        deleteButton.tintColor = UIColor.red
        
        // configure alarm for event
        let daysToSubtract = Int(record.weeksBeforeReminder)*(-7)
        
        var addingPeriod = DateComponents()
        addingPeriod.day = daysToSubtract
        addingPeriod.hour = 12
        
        let userCalendar = NSCalendar.current
        let alarmDate = userCalendar.date(byAdding: addingPeriod, to: record.warrantyEnds as! Date) // this is really subtracting...
        alertDateLabel.text = dateFormatter.string(from: alarmDate!)
        // register for previewing with 3d touch
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: view)
        } else {
            print("3D Touch Not Available")
        }
    }
    
    @IBAction func editButtonPressed(_ sender: Any) {
        if isEditingRecord {
            editButton.title = "Edit"
            isEditingRecord = false
            navBar.setHidesBackButton(isEditingRecord, animated: true)
            navigationController?.setToolbarHidden(true, animated: true)
        } else {
            editButton.title = "Done"
            isEditingRecord = true
            navBar.setHidesBackButton(isEditingRecord, animated: true)
            navigationController?.setToolbarHidden(false, animated: true)
            
        }
    }
    
    @IBAction func deleteButtonPressed(_ sender: Any) {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        let managedContext =
            appDelegate.persistentContainer.viewContext
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Record")
        fetchRequest.predicate = NSPredicate(format: "dateCreated==%@", record.dateCreated!)
        let object = try! managedContext.fetch(fetchRequest)
        managedContext.delete(object[0]) // delete first returned object
        
        self.navigationController!.popToRootViewController(animated: true)
    }
    
    //MARK: Peek and Pop methods
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        print("Recognized force touch")
        
        guard let imageViewController =
            storyboard?.instantiateViewController(
                withIdentifier: "ImageViewController") as?
            ImageViewController else {
                return nil
        }
        
        var selectedImageView: UIImageView!
        if itemImageView.frame.contains(location) {
            selectedImageView = itemImageView
        } else if receiptImageView.frame.contains(location) {
            selectedImageView = receiptImageView
        } else {
            return nil
        }
       
        imageViewController.image = selectedImageView.image!
        
        imageViewController.preferredContentSize =
            CGSize(width: 0.0, height: 600)
        
        previewingContext.sourceRect = selectedImageView.frame
        
        return imageViewController
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
    
    // MARK: Prepare for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "toCellDetails") {
//            if let nextViewController = segue.destination as? DetailsViewController {
//                if (selectedRecord != nil) {
//                    nextViewController.record = selectedRecord
//                    nextViewController.itemImageData = selectedRecord.itemImage
//                    nextViewController.receiptImageData = selectedRecord.receiptImage
//                } else {
//                    print("Selected Record was nil")
//                }
//            }
        }
    }
}
