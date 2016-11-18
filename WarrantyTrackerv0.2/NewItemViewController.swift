//
//  NewItemViewController.swift
//  WarrantyTrackerv0.2
//
//  Created by Jeff Chimney on 2016-11-01.
//  Copyright © 2016 Jeff Chimney. All rights reserved.
//

import UIKit
import AVFoundation

class NewItemViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVCapturePhotoCaptureDelegate {

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
        navBar.title = "Item"
        
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
    
//    func updateDeviceSettings(focusValue : Float, isoValue : Float) {
//        if let device = captureDevice {
//            do {
//                try captureDevice!.lockForConfiguration()
//                
//            } catch let error as NSError {
//                print(error)
//            }
//            
//            device.setFocusModeLockedWithLensPosition(focusValue, completionHandler: { (time) -> Void in
//                //
//            })
//            
//            // Adjust the iso to clamp between minIso and maxIso based on the active format
//            let minISO = device.activeFormat.minISO
//            let maxISO = device.activeFormat.maxISO
//            let clampedISO = isoValue * (maxISO - minISO) + minISO
//            device.setExposureModeCustomWithDuration(AVCaptureExposureDurationCurrent, iso: clampedISO, completionHandler: { (time) -> Void in
//            })
//            
//            device.unlockForConfiguration()
//            
//        }
//    }
//    
//    func touchPercent(touch : UITouch) -> CGPoint {
//        // Get the dimensions of the screen in points
//        let screenSize = UIScreen.main.bounds.size
//        
//        // Create an empty CGPoint object set to 0, 0
//        var touchPer = CGPoint.zero
//        
//        // Set the x and y values to be the value of the tapped position, divided by the width/height of the screen
//        touchPer.x = touch.location(in: self.view).x / screenSize.width
//        touchPer.y = touch.location(in: self.view).y / screenSize.height
//        
//        // Return the populated CGPoint
//        return touchPer
//    }
//    
//    func focusTo(value : Float) {
//        if let device = captureDevice {
//            do {
//                try captureDevice!.lockForConfiguration()
//                
//            } catch let error as NSError {
//                print(error)
//            }
//            
//            device.setFocusModeLockedWithLensPosition(value, completionHandler: { (time) -> Void in
//                //
//            })
//            device.unlockForConfiguration()
//            
//        }
//    }
//    
//    let screenWidth = UIScreen.main.bounds.size.width
//    
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        //if let touchPer = touches.first {
//        let touchPer = touchPercent( touch: touches.first! as UITouch )
//        updateDeviceSettings(focusValue: Float(touchPer.x), isoValue: Float(touchPer.y))
//        
//        
//        super.touchesBegan(touches, with:event)
//    }
//    
//    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//        // if let anyTouch = touches.first {
//        let touchPer = touchPercent( touch: touches.first! as UITouch )
//        // let touchPercent = anyTouch.locationInView(self.view).x / screenWidth
//        //      focusTo(Float(touchPercent))
//        updateDeviceSettings(focusValue: Float(touchPer.x), isoValue: Float(touchPer.y))
//    }
    
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
            //captureSession.stopRunning()
            nextButton.title = "Next"
            
        } else {
            
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
        if (segue.identifier == "toReceipt") {
            if let nextViewController = segue.destination as? NewReceiptViewController {
                if (imageView.image != nil) {
                    nextViewController.itemImage = imageView.image
                } else {
                    print("Was nil")
                }
            }
        }
    }
}

