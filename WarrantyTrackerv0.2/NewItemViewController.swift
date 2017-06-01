//
//  NewItemViewController.swift
//  WarrantyTrackerv0.2
//
//  Created by Jeff Chimney on 2016-11-01.
//  Copyright © 2016 Jeff Chimney. All rights reserved.
//

import UIKit
import AVFoundation

class NewItemViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nextButton: UIBarButtonItem!
    @IBOutlet weak var navBar: UINavigationItem!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var libraryButton: UIButton!
    @IBOutlet weak var cameraAccessLabel: UILabel!
    @IBOutlet weak var openSettingsButton: UIButton!
    
    var imageDataToSave: Data!
    let imagePicker = UIImagePickerController()
    var imagePicked = false
    
    // variables that have been passed forward
    var titleString: String! = nil
    var descriptionString: String! = nil
    //

    
    //camera variables
    var session: AVCaptureSession?
    var stillImageOutput: AVCaptureStillImageOutput?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        navBar.title = "Item"
        navigationController?.isToolbarHidden = true
        nextButton.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {        
        if AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) ==  AVAuthorizationStatus.authorized
        {
            // Already Authorized
            openSettingsButton.isHidden = true
            cameraAccessLabel.isHidden = true
            imageView.isHidden = false
            setUpCamera()
        }
        else
        {
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { (granted :Bool) -> Void in
                if granted == true
                {
                    // User granted
                    DispatchQueue.main.async {
                        UserDefaultsHelper.setCameraPermissions(to: true)
                        self.imageView.isHidden = false
                        self.openSettingsButton.isHidden = true
                        self.cameraAccessLabel.isHidden = true
                        self.setUpCamera()
                        self.captureButton.isEnabled = true
                    }
                }
                else
                {
                    // User Rejected
                    DispatchQueue.main.async {
                        UserDefaultsHelper.setCameraPermissions(to: false)
                        self.imageView.isHidden = true
                        self.cameraAccessLabel.isHidden = false
                        self.openSettingsButton.isHidden = false
                        self.captureButton.isEnabled = false;
                    }
                }
            });
        }
    }
    
    func setUpCamera() {
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
            videoPreviewLayer!.frame = imageView.bounds
        }
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
                    self.nextButton.isEnabled = true
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
            nextButton.isEnabled = true
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func nextButtonPressed(_ sender: Any) {
        
    }
    
    @IBAction func cameraSwitchPressed(_ sender: Any) {
        guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                print("Settings opened: \(success)") // Prints true
            })
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "toReceipt") {
            if let nextViewController = segue.destination as? NewReceiptViewController {
                if (imageView.image != nil) {
                    nextViewController.itemImageData = imageDataToSave
                    nextViewController.titleString = titleString
                    nextViewController.descriptionString = descriptionString
                } else {
                    print("Was nil")
                }
            }
        }
    }
}

