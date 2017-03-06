//
//  CloudKitHelper.swift
//  WarrantyTrackerv0.2
//
//  Created by Jeff Chimney on 2017-03-06.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation
import CloudKit



class CloudKitHelper {

    static func fetchRecord(recordID: CKRecordID) {
        let publicDatabase:CKDatabase = CKContainer.default().publicCloudDatabase
        publicDatabase.fetch(withRecordID: recordID, completionHandler: ({record, error in
            if let err = error {
                DispatchQueue.main.async() {
                    print(err.localizedDescription)
                }
            } else {
                //return record!
            }
        }))
    }
}
