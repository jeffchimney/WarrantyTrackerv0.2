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

public protocol DataBackDelegate: class {
    func savePreferences (labelText:String, changeStartDate:Bool)
}

class DetailsViewController: UIViewController, UIViewControllerPreviewingDelegate, UITextViewDelegate, UIGestureRecognizerDelegate, UIPopoverPresentationControllerDelegate, DataBackDelegate {

    // variables passed from last view
    var record: Record!
    //
    
    @IBOutlet weak var navBar: UINavigationItem!
    @IBOutlet weak var itemImageView: UIImageView!
    @IBOutlet weak var receiptImageView: UIImageView!
    @IBOutlet weak var startDateLabel: UILabel!
    @IBOutlet weak var endDateLabel: UILabel!
    @IBOutlet weak var descriptionView: UITextView!
    @IBOutlet weak var weeksBeforeLabel: UILabel!
    @IBOutlet weak var weeksBeforeLabel2: UILabel!
    @IBOutlet weak var alertDateLabel: UILabel!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var weeksBeforeSegment: UISegmentedControl!
    
    var originalDescriptionViewCenter = CGPoint(x: 0, y: 0)
    var originalWeeksBeforeEndDateCenter = CGPoint(x: 0, y: 0)
    
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
        descriptionView.textAlignment = .center
        descriptionView.delegate = self
        weeksBeforeLabel.text = String(record.weeksBeforeReminder) + " weeks before end date"
        weeksBeforeLabel2.text = weeksBeforeLabel.text
        weeksBeforeSegment.selectedSegmentIndex = record.weeksBeforeReminder-1
        weeksBeforeSegment.alpha = 0
        weeksBeforeLabel2.alpha = 0
        
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
        
        originalDescriptionViewCenter = descriptionView.center
        originalWeeksBeforeEndDateCenter = weeksBeforeLabel.center
        
        let startDateTap = UITapGestureRecognizer(target: self, action: #selector(startDateTapped(sender:)))
        let endDateTap = UITapGestureRecognizer(target: self, action: #selector(endDateTapped(sender:)))
        startDateLabel.addGestureRecognizer(startDateTap)
        endDateLabel.addGestureRecognizer(endDateTap)
    }
    
    @IBAction func selectedSegmentChanged(_ sender: Any) {
        weeksBeforeLabel2.text = String(weeksBeforeSegment.selectedSegmentIndex+1) + " weeks before end date"
    }
    
    func startDateTapped(sender: UITapGestureRecognizer) {
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
    
    func endDateTapped(sender: UITapGestureRecognizer) {
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
    
    @IBAction func editButtonPressed(_ sender: Any) {
        if isEditingRecord {
            startDateLabel.isUserInteractionEnabled = false
            endDateLabel.isUserInteractionEnabled = false
            editButton.title = "Edit"
            isEditingRecord = false
            navBar.setHidesBackButton(isEditingRecord, animated: true)
            navigationController?.setToolbarHidden(true, animated: true)
            
            stopJiggling(viewToStop: itemImageView)
            stopJiggling(viewToStop: receiptImageView)
            
            weeksBeforeLabel.text = weeksBeforeLabel2.text
            
            self.descriptionView.textColor = UIColor.black
            self.descriptionView.isUserInteractionEnabled = false
            self.startDateLabel.textColor = UIColor.black
            self.endDateLabel.textColor = UIColor.black
            
            UIView.animate(withDuration: 0.3, animations: {
                self.alertDateLabel.alpha = 1.0
                self.weeksBeforeLabel.alpha = 1.0
                self.weeksBeforeSegment.alpha = 0
                self.weeksBeforeLabel2.alpha = 0
            }, completion: { finished in
                UIView.animate(withDuration: 0.3, animations: {
                    self.weeksBeforeLabel.center = CGPoint(x: self.weeksBeforeLabel.center.x, y: self.alertDateLabel.center.y)
                })
            })
            
            weeksBeforeLabel.text = String(record.weeksBeforeReminder) + " weeks before end date"
        } else {
            startDateLabel.isUserInteractionEnabled = true
            endDateLabel.isUserInteractionEnabled = true
            editButton.title = "Done"
            isEditingRecord = true
            navBar.setHidesBackButton(isEditingRecord, animated: true)
            navigationController?.setToolbarHidden(false, animated: true)
            
            startJiggling(viewToShake: itemImageView)
            startJiggling(viewToShake: receiptImageView)
            
            self.descriptionView.textColor = self.descriptionView.tintColor
            self.descriptionView.isUserInteractionEnabled = true
            self.startDateLabel.textColor = self.startDateLabel.tintColor
            self.endDateLabel.textColor = self.endDateLabel.tintColor
            
            UIView.animate(withDuration: 0.5, animations: {
                self.alertDateLabel.alpha = 0
                self.weeksBeforeLabel.alpha = 0
            }, completion: { finished in
                UIView.animate(withDuration: 0.5, animations: {
                    self.weeksBeforeSegment.alpha = 1.0
                    self.weeksBeforeLabel2.alpha = 1.0
                })
            })
            
            weeksBeforeLabel.text = String(record.weeksBeforeReminder) + " weeks before end date"
        }
    }
    
    func startJiggling(viewToShake: UIImageView) {
        let randomInt: Double = Double(arc4random_uniform(50))
        let r: Double = (randomInt/500.0)+0.5
        
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
    
    // resign first responder on text view return
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            descriptionView.resignFirstResponder()
            return false
        }
        return true
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
        
    }
}
