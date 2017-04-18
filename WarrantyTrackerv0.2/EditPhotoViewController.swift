//
//  EditPhotoViewController.swift
//  WarrantyTrackerv0.2
//
//  Created by Jeff Chimney on 2016-12-14.
//  Copyright © 2016 Jeff Chimney. All rights reserved.
//

import UIKit
import AVFoundation
import CoreData
import CloudKit

class EditPhotoViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var navBar: UINavigationItem!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var libraryButton: UIButton!
    var indexTapped: Int!
    var record: Record!
    var imageID = ""
    
    var imageDataToSave: Data!
    let imagePicker = UIImagePickerController()
    var imagePicked = false
    
    //camera variables
    var session: AVCaptureSession?
    var stillImageOutput: AVCaptureStillImageOutput?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    weak var editImageDelegate: EditImageDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        navigationController?.setToolbarHidden(true, animated: true)
        saveButton.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        if !imagePicked {
            session = AVCaptureSession()
            session!.sessionPreset = AVCaptureSessionPresetPhoto
            let backCamera = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
            
            var error: NSError?
            var input: AVCaptureDeviceInput!
            do {
                input = try AVCaptureDeviceInput(device: backCamera)
            } catch let error1 as NSError {
                error = error1
                input = nil
                print(error!.localizedDescription)
            }
            
            if error == nil && session!.canAddInput(input) {
                session!.addInput(input)
                
                stillImageOutput = AVCaptureStillImageOutput()
                stillImageOutput?.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
                
                if session!.canAddOutput(stillImageOutput) {
                    session!.addOutput(stillImageOutput)
                    videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
                    videoPreviewLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
                    videoPreviewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                    imageView.layer.addSublayer(videoPreviewLayer!)
                    session!.startRunning()
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        videoPreviewLayer!.frame = imageView.bounds
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func openCameraButton(sender: AnyObject) {
        if let videoConnection = stillImageOutput!.connection(withMediaType: AVMediaTypeVideo) {
            stillImageOutput?.captureStillImageAsynchronously(from: videoConnection, completionHandler: { (sampleBuffer, error) -> Void in
                if sampleBuffer != nil {
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                    self.imageDataToSave = imageData
                    let dataProvider = CGDataProvider(data: imageData as! CFData)
                    let cgImageRef = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
                    let image = UIImage(cgImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.right)
                    self.session?.stopRunning()
                    self.imageView.layer.sublayers?.removeAll()
                    self.imageView.contentMode = .scaleAspectFill
                    self.imageView.image = image
                    self.saveButton.isEnabled = true
                }
            })
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
            session?.stopRunning()
            imageView.layer.sublayers?.removeAll()
            imageView.contentMode = .scaleAspectFill
            imageView.image = pickedImage
            imageDataToSave = UIImageJPEGRepresentation(pickedImage, 1.0)
            imagePicked = true
            saveButton.isEnabled = true
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        imageID = UUID().uuidString
        saveImageLocally()
        editImageDelegate?.addNewImage(newImage: UIImage(data: imageDataToSave)!, newID: imageID)
        performSegue(withIdentifier: "unwindToEdit", sender: self)
    }
    
    func saveImageToCloudKit() {
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
                        
                        let ckImage = CKRecord(recordType: "Images")
                        let reference = CKReference(recordID: recordRecord.recordID, action: CKReferenceAction.deleteSelf)
                        
                        let filename = ProcessInfo.processInfo.globallyUniqueString + ".png"
                        let url = NSURL.fileURL(withPath: NSTemporaryDirectory()).appendingPathComponent(filename)
                        
                        do {
                            try self.imageDataToSave.write(to: url, options: NSData.WritingOptions.atomicWrite)
                            
                            let imageAsset = CKAsset(fileURL: url)
                            
                            ckImage.setObject(reference, forKey: "associatedRecord")
                            ckImage.setObject(imageAsset as CKRecordValue?, forKey: "image")
                            ckImage.setObject(self.imageID as CKRecordValue?, forKey: "id")
                            
                            publicDatabase.save(ckImage, completionHandler: { (record, error) in
                                if error != nil {
                                    print(error!)
                                    return
                                }
                                self.saveImageLocally()
                            })
                        }  catch {
                            print("Problems writing to URL")
                        }
                    }
                }
            })
        }
    }
    
    func saveImageLocally() {
        // if not connected to cloudkit, get a new UUID
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let imageEntity = NSEntityDescription.entity(forEntityName: "Image", in: managedContext)!
        let image = NSManagedObject(entity: imageEntity, insertInto: managedContext) as! Image
        
        image.image = imageDataToSave as NSData?
        image.record = record!
        image.id = imageID
        
        do {
            try managedContext.save()
            
            if (UserDefaultsHelper.isSignedIn()) {
                // check what the current connection is.  If wifi, refresh.  If data, and sync by data is enabled, refresh.
                let conn = UserDefaultsHelper.currentConnection()
                if (conn == "wifi" || (conn == "data" && UserDefaultsHelper.canSyncUsingData())) {
                    CloudKitHelper.saveImageToCloud(imageRecord: image, associatedRecord: record)
                } else {
                    // queue up the record to sync when you have a good connection
                    UserDefaultsHelper.addRecordToQueue(recordID: record.recordID!)
                }
            }
            print("Saved image to CoreData")
        } catch {
            print("Problems saving note to CoreData")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "unwindToEdit") {
            if let nextViewController = segue.destination as? DetailsTableViewController {
                if navBar.title == "Item" {
                    if (imageView.image != nil) { // set item image
                        let cell = nextViewController.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as! ImagesTableViewCell
                        //cell.itemImageView.image = imageView.image
                    } else {
                        print("Was nil")
                    }
                } else if navBar.title == "Receipt" {
                    if (imageView.image != nil) { // set receipt image
                        let cell = nextViewController.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as! ImagesTableViewCell
                        //cell.receiptImageView.image = imageView.image
                    } else {
                        print("Was nil")
                    }
                } else {
                    if (imageView.image != nil) { // set receipt image
                        let cell = nextViewController.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as! ImagesTableViewCell
                        //cell.receiptImageView.image = imageView.image
                    } else {
                        print("Was nil")
                    }
                }
            }
        }
    }
}

