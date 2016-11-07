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
    
    required public convenience init?(coder aDecoder: NSCoder) {
        guard let title = aDecoder.decodeObject(forKey: "title") as? String,
        let descriptionString = aDecoder.decodeObject(forKey: "description") as? String,
        let tags = aDecoder.decodeObject(forKey: "tags") as? [String],
        let itemImage = aDecoder.decodeObject(forKey: "itemImage") as? UIImage,
        let receiptImage = aDecoder.decodeObject(forKey: "receiptImage") as? UIImage,
        let hasWarranty = aDecoder.decodeObject(forKey: "hasWarranty") as? Bool,
        let warrantyStarts = aDecoder.decodeObject(forKey: "warrantyStarts") as? Date,
        let warrantyEnds = aDecoder.decodeObject(forKey: "warrantyEnds") as? Date,
        let weeksBeforeReminder = aDecoder.decodeObject(forKey: "weeksBeforeReminder") as? Int
        else {
            return nil
        }
        
        self.init(
            with: title,
            description: descriptionString,
            tags: tags,
            warrantyStarts: warrantyStarts,
            warrantyEnds: warrantyEnds,
            itemImage: itemImage,
            receiptImage: receiptImage,
            weeksBeforeReminder: weeksBeforeReminder,
            hasWarranty: hasWarranty
        )
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
