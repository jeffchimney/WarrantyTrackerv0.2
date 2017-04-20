//
//  CoreDataHelper.swift
//  WarrantyTrackerv0.2
//
//  Created by Jeff Chimney on 2017-03-06.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

class CoreDataHelper {
    
    static func fetchAllRecords(in context: NSManagedObjectContext) -> [Record] {
        // Get associated images
        let recordFetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Record")
        
        var recordRecords: [NSManagedObject] = []
        do {
            recordRecords = try context.fetch(recordFetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        var recordList: [Record] = []
        for record in recordRecords {
            let thisRecord = record as! Record
            
            recordList.append(thisRecord)
        }
        return recordList
    }
    
    static func fetchRecord(with id: String, in context: NSManagedObjectContext) -> Record {
        let predicate = NSPredicate(format: "recordID = %@", id)
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Record")
        fetchRequest.predicate = predicate

        var returnedRecords: [NSManagedObject] = []
        do {
            returnedRecords = try context.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        let record = returnedRecords[0] as! Record

        return record
    }
    
    static func fetchImage(with id: String, in context: NSManagedObjectContext) -> Image {
        let predicate = NSPredicate(format: "id = %@", id)
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Image")
        fetchRequest.predicate = predicate
        
        var returnedImages: [NSManagedObject] = []
        do {
            returnedImages = try context.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        let image = returnedImages[0] as! Image
        
        return image
    }
    
    static func fetchImages(for record: Record, in context: NSManagedObjectContext) -> [Image] {
        // Get associated images
        let imageFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Image")
        let predicate = NSPredicate(format: "record = %@", record)
        imageFetchRequest.predicate = predicate
        
        var imageRecords: [NSManagedObject] = []
        do {
            imageRecords = try context.fetch(imageFetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        var imageList: [Image] = []
        for image in imageRecords {
            let thisImage = image as! Image
            
            imageList.append(thisImage)
        }
        return imageList
    }
    
    static func fetchNote(with id: String, in context: NSManagedObjectContext) -> Note? {
        let predicate = NSPredicate(format: "id = %@", id)
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Note")
        fetchRequest.predicate = predicate
        
        var returnedNotes: [NSManagedObject] = []
        do {
            returnedNotes = try context.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
            return nil
        }
        let note = returnedNotes[0] as! Note
        
        return note
    }
    
    static func fetchNotes(for record: Record, in context: NSManagedObjectContext) -> [Note] {
        // Get associated notes
        let noteFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Note")
        let predicate = NSPredicate(format: "record = %@", record)
        noteFetchRequest.predicate = predicate
        
        var noteRecords: [NSManagedObject] = []
        do {
            noteRecords = try context.fetch(noteFetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        var noteList: [Note] = []
        for note in noteRecords {
            let thisNote = note as! Note
            
            noteList.append(thisNote)
        }
        return noteList
    }
    
    static func save(context: NSManagedObjectContext) {
        // save locally
        do {
            try context.save()
        } catch {
            DispatchQueue.main.async {
                print("Connection error. Try again later.")
            }
            return
        }
    }
    
    static func delete(record: Record, in context: NSManagedObjectContext) {
        var returnedRecords: [NSManagedObject] = []
        
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Record")
        
        do {
            returnedRecords = try context.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        for thisRecord in returnedRecords {
            if record == thisRecord {
                context.delete(thisRecord)
                do {
                    try context.save()
                } catch {
                    print("Error deleting record")
                }
            }
        }
    }
    
    static func deleteAll() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let context = appDelegate.persistentContainer.viewContext
        let entityList = ["Note", "Tag", "Image", "Record", "Account"]
        
        for entity in entityList {
            let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
            
            do {
                try context.execute(deleteRequest)
                try context.save()
                print (entity + "s were successfully deleted.")
            } catch {
                print ("There was an error deleting " + entity)
            }
        }
    }
    
    static func setRecentlyDeletedFalse(for record: Record, in context: NSManagedObjectContext) {
        var returnedRecords: [NSManagedObject] = []
        
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Record")
        
        do {
            returnedRecords = try context.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        for thisRecord in returnedRecords {
            if record == thisRecord {
                let thisRecord = thisRecord as! Record
                thisRecord.recentlyDeleted = false
                do {
                    try context.save()
                } catch {
                    print("Error deleting record")
                }
            }
        }
    }
    
    static func importNotesFromCloudKit(associatedWith: Record, in context: NSManagedObjectContext) {
        let publicDatabase:CKDatabase = CKContainer.default().publicCloudDatabase
        let predicate = NSPredicate(format: "associatedRecord = %@", CKReference(record: CKRecord(recordType: "Notes", recordID: CKRecordID(recordName: associatedWith.recordID!)), action: CKReferenceAction.deleteSelf))
        let query = CKQuery(recordType: "Notes", predicate: predicate)
        
        publicDatabase.perform(query, inZoneWith: nil, completionHandler: { (results, error) in
            if error != nil {
                print("Error pulling from CloudKit")
            } else {
                // pare down results that already exist in the cloud
                for result in results! {
                    let noteEntity = NSEntityDescription.entity(forEntityName: "Note", in: context)!
                    let note = NSManagedObject(entity: noteEntity, insertInto: context) as! Note
                    
                    note.id = result.recordID.recordName
                    note.lastSynced = Date() as NSDate
                    note.title = result.value(forKey: "title") as? String
                    note.noteString = result.value(forKey: "noteString") as? String
                    note.record = associatedWith
                    
                    // save locally
                    do {
                        try context.save()
                        DispatchQueue.main.async {
                            print("Imported notes to core data")
                        }
                    } catch {
                        DispatchQueue.main.async {
                            print("Error importing notes to core data")
                        }
                        return
                    }
                }
            }
        })
    }
    
    static func importImagesFromCloudKit(associatedWith: Record, in context: NSManagedObjectContext) {
        let publicDatabase:CKDatabase = CKContainer.default().publicCloudDatabase
        let predicate = NSPredicate(format: "associatedRecord = %@", CKReference(record: CKRecord(recordType: "Images", recordID: CKRecordID(recordName: associatedWith.recordID!)), action: CKReferenceAction.deleteSelf))
        let query = CKQuery(recordType: "Images", predicate: predicate)
        
        publicDatabase.perform(query, inZoneWith: nil, completionHandler: { (results, error) in
            if error != nil {
                print("Error pulling from CloudKit")
            } else {
                // pare down results that already exist in the cloud
                for result in results! {
                    let imageEntity = NSEntityDescription.entity(forEntityName: "Image", in: context)!
                    let image = NSManagedObject(entity: imageEntity, insertInto: context) as! Image
                    
                    image.lastSynced = Date() as NSDate
                    // CKAssets need to be converted to NSData
                    let imageData = result.value(forKey: "itemData") as! CKAsset
                    image.image = NSData(contentsOf: imageData.fileURL)
                    image.id = result.recordID.recordName
                    image.record = associatedWith
                    
                    // save locally
                    do {
                        try context.save()
                        DispatchQueue.main.async {
                            print("Imported images to core data")
                        }
                    } catch {
                        DispatchQueue.main.async {
                            print("Error importing images to core data")
                        }
                        return
                    }
                }
            }
        })
    }
}
