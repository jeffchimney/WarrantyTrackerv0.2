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

public protocol DataBackDelegate: class {
    func savePreferences (labelText:String, changeStartDate:Bool)
}

class DetailsTableViewController: UITableViewController, UIPopoverPresentationControllerDelegate, DataBackDelegate {
    
    // variables passed from last view
    var record: Record!
    //
    
    var notesCellsArray = [""]
    
    @IBOutlet weak var navBar: UINavigationItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    var isEditingRecord = false
    var tappedItem = false
    var tappedReceipt = false
    var rowsInNotesSection = 0
    var originalCellSize = 0
    let generator = UIImpactFeedbackGenerator(style: .medium)
    
    weak var reloadDelegate: ReloadTableViewDelegate?
    
    override func viewDidLoad() {
        navBar.title = record.title!
        
        tableView.dataSource = self
        tableView.delegate = self
        
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
        let imageCell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as! ImagesTableViewCell
        let startDateCell = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as! InfoTableViewCell
        let endDateCell = tableView.cellForRow(at: IndexPath(row: 1, section: 1)) as! InfoTableViewCell
        
        if isEditingRecord {
            deleteButton.title = "Save"
            deleteButton.tintColor = tableView.tintColor
            startDateCell.isUserInteractionEnabled = false
            endDateCell.isUserInteractionEnabled = false
            editButton.title = "Edit"
            isEditingRecord = false
            navBar.setHidesBackButton(isEditingRecord, animated: true)
            
            stopJiggling(viewToStop: imageCell.itemImageView)
            stopJiggling(viewToStop: imageCell.receiptImageView)
            
            startDateCell.detail.textColor = UIColor.black
            endDateCell.detail.textColor = UIColor.black
            
            // reset bools for tapped image views
            tappedReceipt = false
            tappedItem = false
            
            notesCellsArray.removeLast()
            tableView.beginUpdates()
            tableView.deleteRows(at: [IndexPath(row: notesCellsArray.count, section: 2)], with: UITableViewRowAnimation.fade)
            tableView.endUpdates()
        } else {
            startDateCell.isUserInteractionEnabled = true
            endDateCell.isUserInteractionEnabled = true
            editButton.title = "Done"
            isEditingRecord = true
            navBar.setHidesBackButton(isEditingRecord, animated: true)
            deleteButton.title = "Delete"
            deleteButton.tintColor = UIColor.red
            
            startJiggling(viewToShake: imageCell.itemImageView)
            startJiggling(viewToShake: imageCell.receiptImageView)
            
            startDateCell.detail.textColor = tableView.tintColor
            endDateCell.detail.textColor = tableView.tintColor
            
            notesCellsArray.append("")
            print(notesCellsArray.count)
            tableView.beginUpdates()
            tableView.insertRows(at: [IndexPath(row: notesCellsArray.count-1, section: 2)], with: UITableViewRowAnimation.fade)
            tableView.endUpdates()
        }
    }
    
    func startDateTapped() {
        generator.impactOccurred()
        let startDateCell = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as! InfoTableViewCell
        // set up the popover presentation controller
        let popController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DatePicker")  as! EditDateController
        popController.modalPresentationStyle = UIModalPresentationStyle.popover
        popController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.down
        popController.popoverPresentationController?.delegate = self
        popController.popoverPresentationController?.sourceView = startDateCell.detail
        popController.popoverPresentationController?.sourceRect = CGRect(x: startDateCell.detail.bounds.midX, y: startDateCell.detail.bounds.minY, width: 0, height: 0)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        popController.pickedDate = dateFormatter.date(from: startDateCell.detail.text!)
        popController.tappedStartDate = true
        
        // present the popover
        popController.delegate = self
        self.present(popController, animated: true, completion: nil)
    }
    
    func endDateTapped() {
        generator.impactOccurred()
        let endDateCell = tableView.cellForRow(at: IndexPath(row: 1, section: 1)) as! InfoTableViewCell
        // set up the popover presentation controller
        let popController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DatePicker") as! EditDateController
        popController.modalPresentationStyle = UIModalPresentationStyle.popover
        popController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.down
        popController.popoverPresentationController?.delegate = self
        popController.popoverPresentationController?.sourceView = endDateCell.detail
        popController.popoverPresentationController?.sourceRect = CGRect(x: endDateCell.detail.bounds.midX, y: endDateCell.detail.bounds.minY, width: 0, height: 0)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        popController.pickedDate = dateFormatter.date(from: endDateCell.detail.text!)
        popController.tappedStartDate = false
        
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
            let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as! InfoTableViewCell
            cell.detail.text = labelText
        } else {
            let cell = tableView.cellForRow(at: IndexPath(row: 1, section: 1)) as! InfoTableViewCell
            cell.detail.text = labelText
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
            self.reloadDelegate?.reloadLastControllerTableView()
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
            
            let imageCell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as! ImagesTableViewCell
            let startDateCell = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as! InfoTableViewCell
            let endDateCell = tableView.cellForRow(at: IndexPath(row: 1, section: 1)) as! InfoTableViewCell
            let descriptionCell = tableView.cellForRow(at: IndexPath(row: 0, section: 2)) as! NotesTableViewCell
            
            record.warrantyStarts = dateFormatter.date(from: startDateCell.detail.text!) as NSDate?
            record.warrantyEnds = dateFormatter.date(from: endDateCell.detail.text!) as NSDate?
            record.descriptionString = descriptionCell.title.text
            //record.weeksBeforeReminder = weeksBeforeSegment.selectedSegmentIndex+1
            record.itemImage = UIImageJPEGRepresentation(imageCell.itemImageView.image!, 1.0) as NSData?
            record.receiptImage = UIImageJPEGRepresentation(imageCell.receiptImageView.image!, 1.0) as NSData?
            
            do {
                try managedContext.save()
                
                let eventStore = EKEventStore()
                let calendars = eventStore.calendars(for: .event)
                
                for calendar in calendars {
                    if calendar.title == "WarrantyTracker" {
                        let event = eventStore.event(withIdentifier: record.eventIdentifier!)
                        
                        event?.startDate = dateFormatter.date(from: endDateCell.detail.text!)!
                        let endDate = dateFormatter.date(from: endDateCell.detail.text!)!
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
    
    func textButtonTapped(sender: Any) {
        
    }
    
    func imageButtonTapped(sender: Any) {
        
    }
    
    // MARK: Table View Delegate Methods
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section == 2 {
            // count rows in Notes section
            rowsInNotesSection += 1
            //print(rowsInNotesSection)
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        if section == 1 {
            return 4
        }
        if section == 2 {
            return notesCellsArray.count
        }
        else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Images"
        }
        if section == 1 {
            return "Info"
        }
        if section == 2 {
            return "Notes"
        }
        else {
            return ""
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Images Cell
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "imagesCell", for: indexPath) as! ImagesTableViewCell
            
            cell.itemImageView.image = UIImage(data: record.itemImage as! Data)
            cell.receiptImageView.image = UIImage(data: record.receiptImage as! Data)
            
            // item view gesture recognizer setup
            let itemViewTap = UITapGestureRecognizer(target: self, action: #selector(itemViewTapped(sender:)))
            let receiptViewTap = UITapGestureRecognizer(target: self, action: #selector(receiptViewTapped(sender:)))
            cell.itemImageView.isUserInteractionEnabled = true
            cell.receiptImageView.isUserInteractionEnabled = true
            cell.itemImageView.addGestureRecognizer(itemViewTap)
            cell.receiptImageView.addGestureRecognizer(receiptViewTap)
            
            return cell
        }
        // Info Cells
        if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "infoCell", for: indexPath) as! InfoTableViewCell
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d, yyyy"
            
            if indexPath.row == 0 {
                cell.title.text = "Start Date"
                cell.detail.text = dateFormatter.string(from: record.warrantyStarts as! Date)
            }
            if indexPath.row == 1 {
                cell.title.text = "End Date"
                cell.detail.text = dateFormatter.string(from: record.warrantyEnds as! Date)
            }
            if indexPath.row == 2 {
                
                // calculate alarm for event
                let daysToSubtract = Int(-record.daysBeforeReminder)
                
                var addingPeriod = DateComponents()
                addingPeriod.day = daysToSubtract
                addingPeriod.hour = 12
                
                let userCalendar = NSCalendar.current
                let alarmDate = userCalendar.date(byAdding: addingPeriod, to: record.warrantyEnds as! Date) // this is really subtracting...
                
                cell.title.text = "Scheduled Alert"
                cell.detail.text = dateFormatter.string(from: alarmDate!)
            }
            if indexPath.row == 3 {
                let calendar = NSCalendar.current
                // Replace the hour (time) of both dates with 00:00
                let currentDate = calendar.startOfDay(for: Date())
                let endDate = calendar.startOfDay(for: record.warrantyEnds as! Date)
                let daysLeft = calendar.dateComponents([.day], from: currentDate, to: endDate)
                
                cell.title.text = "Days Remaining"
                cell.detail.text = String(daysLeft.day!)
            }
            
            return cell
        }
        // Notes cells
        if indexPath.section == 2 {
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "notesCell", for: indexPath) as! NotesTableViewCell
            
                cell.title.text = record.descriptionString
                return cell
            } else if indexPath.row+1 < notesCellsArray.count {
                print(String(indexPath.row) + " < " + String(notesCellsArray.count))
                let cell = tableView.dequeueReusableCell(withIdentifier: "notesCell", for: indexPath) as! NotesTableViewCell
                
                cell.title.text = record.descriptionString
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "addCell", for: indexPath) as! AddTableViewCell
                cell.hiddenAddButton.isHidden = true
                cell.textButton.addTarget(self, action: #selector(textButtonTapped(sender:)), for: .touchUpInside)
                cell.imageButton.addTarget(self, action: #selector(imageButtonTapped(sender:)), for: .touchUpInside)
                return cell
            }
        }
        // shouldnt get called.
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "addCell", for: indexPath) as! AddTableViewCell
            return cell
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
                if indexPath.row == 2 {
                
                }
            }
            
            // NOTES
//            if indexPath.section == 2 {
//                for index in 0...rowsInNotesSection {
//                    if indexPath.row == index {
//                        let selectedCell = tableView.cellForRow(at: indexPath)
//                        let cellLabel = selectedCell?.contentView.subviews[0] as! UILabel
//                        cellLabel.numberOfLines = 0
//                    }
//                }
//            }
        }
        
        // NOTES
//        if indexPath.section == 2 {
//            for index in 0...rowsInNotesSection {
//                if indexPath.row == index {
//                    let selectedCell = tableView.cellForRow(at: indexPath) as! NotesTableViewCell
//                    let cellLabel = selectedCell.contentView.subviews[0] as! UILabel
//                    
//                }
//            }
//        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 240
        } else {
            return 55
        }
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 240
        } else {
            return 55
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
