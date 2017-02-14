//
//  NoteViewController.swift
//  WarrantyTrackerv0.2
//
//  Created by Jeff Chimney on 2017-01-24.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit
import CloudKit
import CoreData

class NoteViewController: UIViewController, UITextFieldDelegate {
    
    // variables passed from last view
    var record: Record!
    //
    
    @IBOutlet weak var noteTitle: UITextField!
    @IBOutlet weak var noteBody: UITextView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var navBar: UINavigationItem!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    weak var handleNotesDelegate: HandleNotesDelegate?
    
    override func viewDidLoad() {
        noteTitle.text = ""
        noteTitle.placeholder = "Title"
        noteTitle.borderStyle = .none
        noteTitle.becomeFirstResponder()
        indicator.isHidden = true
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        noteTitle.resignFirstResponder()
        noteBody.resignFirstResponder()
        indicator.isHidden = false
        indicator.startAnimating()
        indicator.activityIndicatorViewStyle = .gray
        saveNoteToCloudKit()// save note locally now and to cloudkit in the background
        saveNoteLocally()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        noteTitle.resignFirstResponder()
        noteBody.becomeFirstResponder()
        return false
    }
    
    func saveNoteToCloudKit() {
        let defaults = UserDefaults.standard
        let username = defaults.string(forKey: "username")
        if username != nil {
            let publicDatabase:CKDatabase = CKContainer.default().publicCloudDatabase
            
            let predicate = NSPredicate(format: "recordID = %@", CKRecordID(recordName: record.recordID!))
            let query = CKQuery(recordType: "Records", predicate: predicate)
            var recordRecord = CKRecord(recordType: "Records")
            publicDatabase.perform(query, inZoneWith: nil, completionHandler: { (results, error) in
                if error != nil {
                    print("Error retrieving from cloudkit")
                } else {
                    if (results?.count)! > 0 {
                        recordRecord = (results?[0])!
                        
                        let ckNote = CKRecord(recordType: "Notes")
                        let reference = CKReference(recordID: recordRecord.recordID, action: CKReferenceAction.deleteSelf)
                        
                        ckNote.setObject(reference, forKey: "associatedRecord")
                        ckNote.setObject(self.noteTitle.text as CKRecordValue?, forKey: "title")
                        ckNote.setObject(self.noteBody.text as CKRecordValue?, forKey: "noteString")
                            
                        publicDatabase.save(ckNote, completionHandler: { (record, error) in
                            if error != nil {
                            print(error!)
                                return
                            }
                        })
                        
                    }
                }
            })
        }
    }
    
    func saveNoteLocally() {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let noteEntity = NSEntityDescription.entity(forEntityName: "Note", in: managedContext)!
        let note = NSManagedObject(entity: noteEntity, insertInto: managedContext) as! Note
        
        note.title = noteTitle.text
        note.noteString = noteBody.text
        note.record = record!
        
        do {
            try managedContext.save()
            print("Saved note to CoreData")
        } catch {
            print("Problems saving note to CoreData")
        }
        handleNotesDelegate?.passBack(newNote: note)
        performSegue(withIdentifier: "unwindFromCreateNote", sender: self)
    }
}
