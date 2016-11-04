//
//  NewReceiptViewController.swift
//  WarrantyTrackerv0.2
//
//  Created by Jeff Chimney on 2016-11-01.
//  Copyright © 2016 Jeff Chimney. All rights reserved.
//

import UIKit

class NewReceiptViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // variables that have been passed forward
    var itemImage: UIImage! = nil
    //
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nextButton: UIBarButtonItem!
    @IBOutlet weak var navBar: UINavigationItem!
    
    var imageToSave: UIImage!
    let imagePicker = UIImagePickerController()
    var imagePicked = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        navBar.title = "Receipt"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if imagePicked {
            nextButton.title = "Next"
        } else {
            nextButton.title = "Skip"
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func openCameraButton(sender: AnyObject) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
            imagePicker.sourceType = UIImagePickerControllerSourceType.camera;
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    @IBAction func openPhotoLibraryButton(sender: AnyObject) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary) {
            imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary;
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imageView.contentMode = .scaleAspectFit
            imageView.image = pickedImage
            imagePicked = true
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func nextButtonPressed(_ sender: Any) {
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "toDates") {
            if let nextViewController = segue.destination as? WarrantyBeginsEndsViewController {
                if (itemImage != nil) {
                    nextViewController.itemImage = itemImage
                }
                if (imageView.image != nil) {
                    nextViewController.receiptImage = imageView.image
                }
            }
        }
    }
}

