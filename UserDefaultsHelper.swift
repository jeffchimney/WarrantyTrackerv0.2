//
//  UserDefaultsHelper.swift
//  WarrantyTrackerv0.2
//
//  Created by Jeff Chimney on 2017-04-12.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation

let defaults = UserDefaults.standard

class UserDefaultsHelper {
    
    static func getUsername() -> String {
        return defaults.object(forKey: "username") as! String
    }
    
    static func getPassword() -> String {
        return defaults.object(forKey: "password") as! String
    }
    
    static func isSignedIn() -> Bool {
        return defaults.object(forKey: "SignedIn") as! Bool
    }
    
    static func isSignedIn(bool: Bool) {
        defaults.set(bool, forKey: "SignedIn")
    }
    
    static func canSyncUsingData() -> Bool {
        return defaults.object(forKey: "SyncUsingData") as! Bool
    }
    
    static func currentConnection() -> String {
        return defaults.object(forKey: "connection") as! String
    }
    
    static func getQueuedChanges() -> [String]? {
        return  defaults.object(forKey: "recordQueue") as? [String]
    }
    
    static func addRecordToQueue(recordID: String) {
        var queuedRecords = defaults.object(forKey: "recordQueue") as! [String]?
        
        if queuedRecords != nil {
            if !(queuedRecords?.contains(recordID))! {
                queuedRecords!.append(recordID)
            }
        } else {
            queuedRecords = []
            queuedRecords!.append(recordID)
        }
        defaults.set(queuedRecords, forKey: "recordQueue")
    }
    
    static func setQueueToEmpty() {
        defaults.set([], forKey: "recordQueue")
    }
}
