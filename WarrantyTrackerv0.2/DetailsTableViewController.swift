//
//  DetailsTableViewController.swift
//  WarrantyTrackerv0.2
//
//  Created by Jeff Chimney on 2017-01-10.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import CloudKit
import EventKit

class DetailsTableViewController: UITableViewController, UIPopoverPresentationControllerDelegate, DataBackDelegate {
    
    // variables passed from last view
    var record: Record!
    //
    
    @IBOutlet weak var itemImageView: UIImageView!
    @IBOutlet weak var receiptImageView: UIImageView!
    @IBOutlet weak var startDateLabel: UILabel!
    @IBOutlet weak var endDateLabel: UILabel!
    @IBOutlet weak var scheduledAlertLabel: UILabel!
    @IBOutlet weak var daysRemainingLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var navBar: UINavigationItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    var isEditingRecord = false
    var tappedItem = false
    var tappedReceipt = false
    var rowsInNotesSection = 0
    var originalCellSize = 0
    let generator = UIImpactFeedbackGenerator(style: .medium)
    
    override func viewDidLoad() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        navBar.title = record.title!
        itemImageView.image = UIImage(data: record.itemImage as! Data)
        receiptImageView.image = UIImage(data: record.receiptImage as! Data)
        startDateLabel.text = dateFormatter.string(from: record.warrantyStarts as! Date)
        endDateLabel.text = dateFormatter.string(from: record.warrantyEnds as! Date)
        
        // calculate alarm for event
        let daysToSubtract = Int(-record.daysBeforeReminder)
        
        var addingPeriod = DateComponents()
        addingPeriod.day = daysToSubtract
        addingPeriod.hour = 12
        
        let userCalendar = NSCalendar.current
        let alarmDate = userCalendar.date(byAdding: addingPeriod, to: record.warrantyEnds as! Date) // this is really subtracting...
        scheduledAlertLabel.text = dateFormatter.string(from: alarmDate!)
        
        let calendar = NSCalendar.current
        // Replace the hour (time) of both dates with 00:00
        let currentDate = calendar.startOfDay(for: Date())
        let endDate = calendar.startOfDay(for: record.warrantyEnds as! Date)
        let daysLeft = calendar.dateComponents([.day], from: currentDate, to: endDate)
        
        daysRemainingLabel.text = String(daysLeft.day!)
        descriptionLabel.text = record.descriptionString
        
        // item view gesture recognizer setup
        let itemViewTap = UITapGestureRecognizer(target: self, action: #selector(itemViewTapped(sender:)))
        let receiptViewTap = UITapGestureRecognizer(target: self, action: #selector(receiptViewTapped(sender:)))
        itemImageView.isUserInteractionEnabled = true
        receiptImageView.isUserInteractionEnabled = true
        itemImageView.addGestureRecognizer(itemViewTap)
        receiptImageView.addGestureRecognizer(receiptViewTap)
        
        // register for previewing with 3d touch
//        if traitCollection.forceTouchCapability == .available {
//            registerForPreviewing(with: self, sourceView: view)
//        } else {
//            print("3D Touch Not Available")
//        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setToolbarHidden(false, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.setToolbarHidden(true, animated: true)
    }
    
    func startJiggling(viewToShake: UIImageView) {
        let randomInt: Double = Double(arc4random_uniform(50))
        let r: Double = (randomInt/2000.0)+0.5
        
        let leftWobble = CGAffineTransform(rotationAngle: CGFloat(degreesToRadians(x: (1.0 * -1.0) - r )))
        let rightWobble = CGAffineTransform(rotationAngle: CGFloat(degreesToRadians(x: 1.0 + r )))
        
        viewToShake.transform = leftWobble
        
        viewToShake.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        UIView.animate(withDuration: 0.1, delay: 0, options: [UIViewAnimationOptions.allowUserInteraction, UIViewAnimationOptions.repeat, UIViewAnimationOptions.autoreverse], animations: {
            viewToShake.animationRepeatCount = NSNotFound
            viewToShake.transform = rightWobble
        }, completion: nil)
    }
    
    func stopJiggling(viewToStop: UIView) {
        viewToStop.layer.removeAllAnimations()
        viewToStop.transform = CGAffineTransform.identity
    }
    
    func degreesToRadians(x: Double) -> Double {
        return (M_PI * x)/180.0
    }
    
    
    
    // DURING EDITING /////////////////////////////////////////////////////////////////////////
    
    @IBAction func editButtonPressed(_ sender: Any) {
        if isEditingRecord {
            deleteButton.title = "Save"
            deleteButton.tintColor = startDateLabel.tintColor
            startDateLabel.isUserInteractionEnabled = false
            endDateLabel.isUserInteractionEnabled = false
            editButton.title = "Edit"
            isEditingRecord = false
            navBar.setHidesBackButton(isEditingRecord, animated: true)
            
            stopJiggling(viewToStop: itemImageView)
            stopJiggling(viewToStop: receiptImageView)
            
            self.startDateLabel.textColor = UIColor.black
            self.endDateLabel.textColor = UIColor.black
            
            // reset bools for tapped image views
            tappedReceipt = false
            tappedItem = false
        } else {
            startDateLabel.isUserInteractionEnabled = true
            endDateLabel.isUserInteractionEnabled = true
            editButton.title = "Done"
            isEditingRecord = true
            navBar.setHidesBackButton(isEditingRecord, animated: true)
            deleteButton.title = "Delete"
            deleteButton.tintColor = UIColor.red
            
            startJiggling(viewToShake: itemImageView)
            startJiggling(viewToShake: receiptImageView)
            
            self.startDateLabel.textColor = self.startDateLabel.tintColor
            self.endDateLabel.textColor = self.endDateLabel.tintColor
        }
    }
    
    func startDateTapped() {
        generator.impactOccurred()
        // set up the popover presentation controller
        let popController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DatePicker")  as! EditDateController
        popController.modalPresentationStyle = UIModalPresentationStyle.popover
        popController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.down
        popController.popoverPresentationController?.delegate = self
        popController.popoverPresentationController?.sourceView = startDateLabel
        popController.popoverPresentationController?.sourceRect = CGRect(x: self.startDateLabel.bounds.midX, y: self.startDateLabel.bounds.minY, width: 0, height: 0)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        popController.pickedDate = dateFormatter.date(from: startDateLabel.text!)
        popController.tappedStartDate = true
        
        // present the popover
        popController.delegate = self
        self.present(popController, animated: true, completion: nil)
    }
    
    func endDateTapped() {
        generator.impactOccurred()
        // set up the popover presentation controller
        let popController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DatePicker") as! EditDateController
        popController.modalPresentationStyle = UIModalPresentationStyle.popover
        popController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.down
        popController.popoverPresentationController?.delegate = self
        popController.popoverPresentationController?.sourceView = endDateLabel
        popController.popoverPresentationController?.sourceRect = CGRect(x: self.endDateLabel.bounds.midX, y: self.endDateLabel.bounds.minY, width: 0, height: 0)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        popController.pickedDate = dateFormatter.date(from: endDateLabel.text!)
        popController.tappedStartDate = false
        
        navBar.title = record.title!
        itemImageView.image = UIImage(data: record.itemImage as! Data)
        
        // present the popover
        popController.delegate = self
        self.present(popController, animated: true, completion: nil)
    }
    
    func itemViewTapped(sender: UITapGestureRecognizer) {
        // show controller to take photo
        if isEditingRecord {
            tappedItem = true
            tappedReceipt = false
            generator.impactOccurred()
            performSegue(withIdentifier: "editImage", sender: self)
        }
    }
    
    func receiptViewTapped(sender: UITapGestureRecognizer) {
        // show controller to take photo
        if isEditingRecord {
            generator.impactOccurred()
            tappedReceipt = true
            tappedItem = false
            performSegue(withIdentifier: "editImage", sender: self)
        }
    }
    
    func savePreferences (labelText:String, changeStartDate:Bool) {
        if changeStartDate {
            startDateLabel.text = labelText
        } else {
            endDateLabel.text = labelText
        }
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    func presentationController(_ controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        return UINavigationController(rootViewController: controller.presentedViewController)
    }
    
    //////////////////////////////////////////////////////////////////////////
    
    override var previewActionItems: [UIPreviewActionItem] {
        
        let delete = UIPreviewAction(title: "Delete", style: .destructive, handler: {_,_ in
            self.setRecentlyDeletedTrue(for: self.record)
        })
        
        let cancel = UIPreviewAction(title: "Cancel", style: .default) { (action, controller) in
            print("Cancel Action Selected")
        }
        
        return [delete, cancel]
    }
    
    func setRecentlyDeletedTrue(for record: Record) {
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
                thisRecord.recentlyDeleted = true
                thisRecord.dateDeleted = Date() as NSDate?
                do {
                    try managedContext.save()
                } catch {
                    print("Error deleting record")
                }
            }
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
        
        if deleteButton.title == "Delete" { // delete first returned object
            let record = object[0] as! Record
            
            record.recentlyDeleted = true
            record.dateDeleted = Date() as NSDate?
            do {
                try managedContext.save()
            } catch {
                print("The record couldn't be updated.")
            }
        } else { // save or update the returned object
            let record = object[0] as! Record
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d, yyyy"
            
            record.warrantyStarts = dateFormatter.date(from: startDateLabel.text!) as NSDate?
            record.warrantyEnds = dateFormatter.date(from: endDateLabel.text!) as NSDate?
            record.descriptionString = descriptionLabel.text
            //record.weeksBeforeReminder = weeksBeforeSegment.selectedSegmentIndex+1
            record.itemImage = UIImageJPEGRepresentation(itemImageView.image!, 1.0) as NSData?
            record.receiptImage = UIImageJPEGRepresentation(receiptImageView.image!, 1.0) as NSData?
            
            do {
                try managedContext.save()
                
                let eventStore = EKEventStore()
                let calendars = eventStore.calendars(for: .event)
                
                for calendar in calendars {
                    if calendar.title == "WarrantyTracker" {
                        let event = eventStore.event(withIdentifier: record.eventIdentifier!)
                        
                        event?.startDate = dateFormatter.date(from: endDateLabel.text!)!
                        let endDate = dateFormatter.date(from: endDateLabel.text!)!
                        event?.endDate = endDate
                        event?.isAllDay = true
                        
                        // remove old alarm and configure new alarm for event
                        if (event?.hasAlarms)! {
                            event?.alarms?.removeAll()
                        }
                        
                        //let daysToSubtract = (weeksBeforeSegment.selectedSegmentIndex+1)*(-7)
                        
                        var addingPeriod = DateComponents()
                        //addingPeriod.day = daysToSubtract
                        addingPeriod.hour = 12
                        
                        let userCalendar = NSCalendar.current
                        let alarmDate = userCalendar.date(byAdding: addingPeriod, to: endDate) // this is really subtracting...
                        
                        let alarm = EKAlarm(absoluteDate: alarmDate!)
                        event?.addAlarm(alarm)
                        
                        do {
                            try eventStore.save(event!, span: .thisEvent, commit: true)
                        } catch {
                            print("The event couldnt be updated")
                        }
                    }
                }
            } catch {
                print("The record couldn't be saved.")
            }
        }
        
        self.navigationController!.popToRootViewController(animated: true)
    }
    
    // MARK: Table View Delegate Methods
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section == 2 {
            // count rows in Notes section
            rowsInNotesSection += 1
            print(rowsInNotesSection)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // INFO ROWS
        if isEditingRecord {
            if indexPath.section == 1 {
                if indexPath.row == 0 { // start date tapped
                    startDateTapped()
                }
                if indexPath.row == 1 { // end date tapped
                    endDateTapped()
                }
                if indexPath.row == 2 { // end date tapped
                
                }
            }
            
            // NOTES
            if indexPath.section == 2 {
                for index in 0...rowsInNotesSection {
                    if indexPath.row == index {
                        let selectedCell = tableView.cellForRow(at: indexPath)
                        let cellLabel = selectedCell?.contentView.subviews[0] as! UILabel
                        cellLabel.numberOfLines = 0
                    }
                }
            }
        }
        
        // NOTES
        if indexPath.section == 2 {
            for index in 0...rowsInNotesSection {
                if indexPath.row == index {
                    let selectedCell = tableView.cellForRow(at: indexPath)
                    let cellLabel = selectedCell?.contentView.subviews[0] as! UILabel
                    
                }
            }
        }
    }
    
    // MARK: Segues
    @IBAction func unwindToEdit(with segue: UIStoryboardSegue) {}
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editImage" {
            if let nextViewController = segue.destination as? EditPhotoViewController {
                if tappedItem {
                    nextViewController.navBar.title = "Item"
                } else if tappedReceipt {
                    nextViewController.navBar.title = "Receipt"
                }
            }
        }
    }
}
