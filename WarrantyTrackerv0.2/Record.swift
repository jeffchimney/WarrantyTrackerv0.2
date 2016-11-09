//
//  Record.swift
//  WarrantyTrackerv0.2
//
//  Created by Jeff Chimney on 2016-11-05.
//  Copyright © 2016 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit

@objc(Record)
public class Record: NSObject, NSCoding {
    var title: String = ""
    var descriptionString: String = ""
    var tags: Array<String> = []
    var itemImage: UIImage! = nil
    var receiptImage: UIImage! = nil
    var hasWarranty: Bool = true
    var warrantyStarts: Date? = nil
    var warrantyEnds: Date? = nil
    var weeksBeforeReminder: Int = 0
    
    init (with title: String, description: String?, tags: Array<String>, warrantyStarts: Date?, warrantyEnds: Date?, itemImage: UIImage?, receiptImage: UIImage?, weeksBeforeReminder: Int, hasWarranty: Bool) {
        // non-optional member variables
        self.title = title
        self.tags = tags
        self.weeksBeforeReminder = weeksBeforeReminder + 1
        self.hasWarranty = hasWarranty
        // optional member variables
        
        if description != nil {
            self.descriptionString = description!
        }
        if warrantyStarts != nil {
            self.warrantyStarts = warrantyStarts!
        }
        if warrantyEnds != nil {
            self.warrantyEnds = warrantyEnds!
        }
        if itemImage != nil {
            self.itemImage = itemImage!
        } else {
            self.itemImage = UIImage()
        }
        if receiptImage != nil {
            self.receiptImage = receiptImage!
        } else {
            self.receiptImage = UIImage()
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        self.title = aDecoder.decodeObject(forKey: "title") as? String ?? ""
        self.descriptionString = aDecoder.decodeObject(forKey: "description") as? String ?? ""
        self.tags = aDecoder.decodeObject(forKey: "tags") as? [String] ?? [""]
        self.itemImage = aDecoder.decodeObject(forKey: "itemImage") as? UIImage
        self.receiptImage = aDecoder.decodeObject(forKey: "receiptImage") as? UIImage
        self.hasWarranty = aDecoder.decodeObject(forKey: "hasWarranty") as? Bool ?? true
        self.warrantyStarts = aDecoder.decodeObject(forKey: "warrantyStarts") as? Date
        self.warrantyEnds = aDecoder.decodeObject(forKey: "warrantyEnds") as? Date
        self.weeksBeforeReminder = aDecoder.decodeObject(forKey: "weeksBeforeReminder") as? Int ?? 1
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.title, forKey: "title")
        aCoder.encode(self.descriptionString, forKey: "descriptionString")
        aCoder.encode(self.tags, forKey: "tags")
        aCoder.encode(self.itemImage, forKey: "itemImage")
        aCoder.encode(self.receiptImage, forKey: "receiptImage")
        aCoder.encode(self.hasWarranty, forKey: "hasWarranty")
        aCoder.encode(self.warrantyStarts, forKey: "warrantyStarts")
        aCoder.encode(self.warrantyEnds, forKey: "warrantyEnds")
        aCoder.encode(self.weeksBeforeReminder, forKey: "weeksBeforeReminder")
    }
}
