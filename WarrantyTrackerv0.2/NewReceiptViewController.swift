//
//  NewReceiptViewController.swift
//  WarrantyTrackerv0.2
//
//  Created by Jeff Chimney on 2016-11-01.
//  Copyright © 2016 Jeff Chimney. All rights reserved.
//

import UIKit
import AVFoundation

class NewReceiptViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVCapturePhotoCaptureDelegate {
    
    // variables that have been passed forward
    var itemImage: UIImage! = nil
    //
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nextButton: UIBarButtonItem!
    @IBOutlet weak var navBar: UINavigationItem!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var libraryButton: UIButton!
    
    var imageToSave: UIImage!
    let imagePicker = UIImagePickerController()
    var imagePicked = false
    
    //camera variables
    let captureSession = AVCaptureSession()
    var captureDevice: AVCaptureDevice?
    var previewLayer: AVCaptureVideoPreviewLayer?
    let stillImageOutput = AVCapturePhotoOutput()
    let settings = AVCapturePhotoSettings()
    var error: NSError?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        navBar.title = "Receipt"
        
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        
        let session = AVCaptureDeviceDiscoverySession(deviceTypes: [AVCaptureDeviceType.builtInWideAngleCamera], mediaType: AVMediaTypeVideo, position: AVCaptureDevicePosition.back)
        
        for device in (session?.devices)! {
            if device.hasMediaType(AVMediaTypeVideo) {
                if device.position == AVCaptureDevicePosition.back {
                    captureDevice = device
                    print("Capture device found!")
                }
            }
        }
        
        if captureDevice != nil {
            beginSession()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if imagePicked {
            nextButton.title = "Next"
        } else {
            nextButton.title = "Next"
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func openCameraButton(sender: AnyObject) {
//        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
//            imagePicker.sourceType = UIImagePickerControllerSourceType.camera;
//            imagePicker.allowsEditing = false
//            self.present(imagePicker, animated: true, completion: nil)
//        }
        capturePicture()
        captureSession.stopRunning()
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
    
    func configureDevice() {
        if captureDevice != nil {
            do {
                try captureDevice!.lockForConfiguration()
            } catch let error as NSError {
                print(error)
            }
            
            captureDevice?.focusMode = .continuousAutoFocus
            captureDevice?.unlockForConfiguration()
        }
    }
    
    func beginSession() {
        configureDevice()
        var deviceInput: AVCaptureDeviceInput!
        do {
            deviceInput = try AVCaptureDeviceInput(device: captureDevice)
        } catch let error as NSError {
            print(error)
            deviceInput = nil
        }
        
        captureSession.addInput(deviceInput)
        if captureSession.canAddOutput(stillImageOutput) {
            captureSession.addOutput(stillImageOutput)
        }
        
        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
        let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                             kCVPixelBufferWidthKey as String: 160,
                             kCVPixelBufferHeightKey as String: 160,
                             ]
        settings.previewPhotoFormat = previewFormat
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.zPosition = 1
        libraryButton.layer.zPosition = 2
        captureButton.layer.zPosition = 2
        self.view.layer.addSublayer(previewLayer!)
        previewLayer?.frame = self.view.layer.frame
        captureSession.startRunning()
        imagePicked = false
        nextButton.title = "Skip"
    }
    
    func capturePicture(){
        self.stillImageOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        if let error = error {
            print(error.localizedDescription)
        }
        
        if let sampleBuffer = photoSampleBuffer, let previewBuffer = previewPhotoSampleBuffer, let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
            
            let image = UIImage(data: imageData, scale: 1.0)
            imageView.image = image
            imageView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
            imagePicked = true
            captureSession.stopRunning()
            nextButton.title = "Next"
            
        } else {
            
        }
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

