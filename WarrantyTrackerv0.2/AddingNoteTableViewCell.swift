//
//  AddingNoteTableViewCell.swift
//  WarrantyTrackerv0.2
//
//  Created by Jeff Chimney on 2017-01-23.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit

class AddingNoteTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleTextView: UITextView!
    @IBOutlet weak var bodyTextView: UITextView!
    
    
    // MARK: TextView Delegates
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            if textView == titleTextView {
                textView.text = "Title"
                textView.textColor = UIColor.lightGray
            } else {
                textView.text = "Note..."
                textView.textColor = UIColor.lightGray
            }
        }
    }
}
