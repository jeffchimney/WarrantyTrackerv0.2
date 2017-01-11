//
//  RecoverCardViewController.swift
//  WarrantyTrackerv0.2
//
//  Created by Jeff Chimney on 2017-01-09.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class RecoverCardViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    var record: Record!
    
    override func viewDidLoad() {
        imageView.image = UIImage(data: record.itemImage as! Data)
    }
    
    override var previewActionItems: [UIPreviewActionItem] {
        let delete = UIPreviewAction(title: "Delete", style: .destructive, handler: {_,_ in
            self.deleteFromCoreData(record: self.record)
        })
        
        let recover = UIPreviewAction(title: "Recover", style: .default, handler: {_,_ in
            self.setRecentlyDeletedFalse(for: self.record)
        })
        
        let cancel = UIPreviewAction(title: "Cancel", style: .default) { (action, controller) in
            print("Cancel Action Selected")
        }
        
        return [delete, recover, cancel]
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
                do {
                    try managedContext.save()
                } catch {
                    print("Error deleting record")
                }
            }
        }
    }
}
