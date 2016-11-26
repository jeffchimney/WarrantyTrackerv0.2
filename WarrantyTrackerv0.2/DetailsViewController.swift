//
//  DetailsViewController.swift
//  WarrantyTrackerv0.2
//
//  Created by Jeff Chimney on 2016-11-24.
//  Copyright © 2016 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit

class DetailsViewController: UIViewController, UIViewControllerPreviewingDelegate {

    var record: Record!
    var itemImageData: NSData!
    var receiptImageData: NSData!
    
    @IBOutlet weak var navBar: UINavigationItem!
    @IBOutlet weak var itemImageView: UIImageView!
    @IBOutlet weak var receiptImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        itemImageView.contentMode = .scaleAspectFit
        receiptImageView.contentMode = .scaleAspectFit
        
        navBar.title = record.title!
        itemImageView.image = UIImage(data: itemImageData as Data)
        receiptImageView.image = UIImage(data: receiptImageData as Data)
        
        // register for previewing with 3d touch
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: view)
        } else {
            print("3D Touch Not Available")
        }
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
        if (segue.identifier == "toCellDetails") {
//            if let nextViewController = segue.destination as? DetailsViewController {
//                if (selectedRecord != nil) {
//                    nextViewController.record = selectedRecord
//                    nextViewController.itemImageData = selectedRecord.itemImage
//                    nextViewController.receiptImageData = selectedRecord.receiptImage
//                } else {
//                    print("Selected Record was nil")
//                }
//            }
        }
    }
}
