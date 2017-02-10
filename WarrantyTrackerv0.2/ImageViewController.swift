//
//  ImageViewController.swift
//  WarrantyTrackerv0.2
//
//  Created by Jeff Chimney on 2016-11-25.
//  Copyright © 2016 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit

class ImageViewController: UIViewController {
    
    var image: UIImage!
    var imageIndex: Int!
    
    @IBOutlet weak var imageView: UIImageView!
    
    weak var deleteImageDelegate: EditImageDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setToolbarHidden(false, animated: false)
        imageView.contentMode = .scaleAspectFit
        imageView.image = image
    }
    
    @IBAction func shareButtonPressed(_ sender: Any) {
        let shareText = "Shared from UnderWarranty."
        
        if let image = image {
            let vc = UIActivityViewController(activityItems: [shareText, image], applicationActivities: [])
            present(vc, animated: true, completion: nil)
        }
    }
    
    override var previewActionItems: [UIPreviewActionItem] {
        
        if imageIndex != 0 && imageIndex != 1 {
            let delete = UIPreviewAction(title: "Delete", style: .destructive, handler: {_,_ in
                self.deleteImageDelegate?.removeImage(index: self.imageIndex)
            })
        
            let cancel = UIPreviewAction(title: "Cancel", style: .default) { (action, controller) in
                print("Cancel Action Selected")
            }
        
            return [delete, cancel]
        } else {
            return []
        }
    }
}
