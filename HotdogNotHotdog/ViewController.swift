//
//  ViewController.swift
//  HotdogNotHotdog
//
//  Created by Nicole Zurita on 5/18/17.
//  Copyright © 2017 Nicole Zurita. All rights reserved.
//
// comment

import UIKit
import AVFoundation
import VisualRecognitionV3

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVCapturePhotoCaptureDelegate {
    
    @IBOutlet weak var tempImageView: UIImageView!
    @IBOutlet weak var cameraView: UIView!
	
	// Array of TagItems
	var tagItems: [TagItem] = []
	
    var captureSession : AVCaptureSession?
    var stillImageOutput : AVCapturePhotoOutput?
    var previewLayer : AVCaptureVideoPreviewLayer?
    var image : UIImage?
	var visualRecognition: VisualRecognition!
	
	let apiKey = "04789d85b44bb93565faec141ce20f83c055e77b"
	let version = "2017-05-19"
	
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
		
        previewLayer?.frame = cameraView.bounds
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        captureSession = AVCaptureSession()
        
    
        captureSession?.sessionPreset = AVCaptureSessionPresetHigh
        
        let backCamera = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        var backCameraError : Error?
        var input : AVCaptureDeviceInput?
       
        do {
            input = try AVCaptureDeviceInput(device: backCamera)
        } catch {
            backCameraError = error
        }
    
        if backCameraError == nil && (captureSession?.canAddInput(input))! {
            captureSession?.addInput(input)
            stillImageOutput = AVCapturePhotoOutput()

            if (captureSession?.canAddOutput(stillImageOutput))! {
                captureSession?.addOutput(stillImageOutput)
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                previewLayer?.videoGravity = AVLayerVideoGravityResizeAspect
                previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.portrait
                cameraView.layer.addSublayer(previewLayer!)
                captureSession?.startRunning()
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "imageCapturedSegue" {
            let controller = segue.destination as! ImageCapturedViewController
            controller.capturedImage = image
        }
    }
    
    
    func didPressTakePhoto() {
        if let videoConnection = stillImageOutput?.connection(withMediaType: AVMediaTypeVideo) {
            videoConnection.videoOrientation = AVCaptureVideoOrientation.portrait
            let photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecJPEG])
            stillImageOutput?.capturePhoto(with: photoSettings, delegate: self)
        }
		
		classifyImage()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
		visualRecognition = VisualRecognition(apiKey: apiKey,
		                                      version: version)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //AVPhotoCapture Delegate function
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
        }
        
        if let sampleBuffer = photoSampleBuffer, let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: nil){
            image = UIImage(data: dataImage)
            performSegue(withIdentifier: "imageCapturedSegue", sender: nil)
        } else {
            print("FAILED AT IMAGE PROCESSING")
        }
        
    }
	
	func failVisualRecognitionWithError(_ error: Error) {
		// Print the error to the console
		print(error)
		// Present an alert to the user describing what the problem may be
		
	}
	
	func classifyImage() {
		// String that will hold the result name from Watson
		var resultName: String!
		// Double that will hold the result scored from Watson
		var resultScore: Double!
		// String that will hold the result score percentage from Watson
		var resultScorePercentage: String!
		// Classify image using Visual Recognition
		
		let recogURL = URL(string: "https://pbs.twimg.com/profile_images/558109954561679360/j1f9DiJi.jpeg")!
        print("right before")
		visualRecognition.detectFaces(inImageFile: recogURL, failure: failVisualRecognitionWithError) {
			detectedFaces in
			// Loop through detected faces
			for detectedFace in detectedFaces.images {
				// Loop through the faces found in detectedFaces
				for face in detectedFace.faces {
					// Set the result name, score and score percentage
					// Handle optional min and max ages
                    print("somehwere inside")
                    resultName = face.gender.gender
                    resultScorePercentage = String(Int(round(face.gender.score * 100))) + "%"
                    print(resultName)
                    print(resultScorePercentage)

					resultScore = face.gender.score
					// Create new tag item based on result name, score and score percentage
					let newTagItem = TagItem(watsonResultName: resultName, watsonResultScore: resultScore, watsonResultScorePercentage: resultScorePercentage)
					// Append the new tag item to the tag items array
					self.tagItems.append(newTagItem)
					// If celebrity match is found add set the result name, score, and score percentage
					if(face.identity != nil){
						resultName = face.identity?.name
						resultScore = face.identity?.score
						resultScorePercentage = String(Int(round(resultScore * 100))) + "% "
						let newTagItem = TagItem(watsonResultName: resultName,
						                         watsonResultScore: resultScore,
						                         watsonResultScorePercentage: resultScorePercentage)
						// Append the new tag item to the tag items array
						self.tagItems.append(newTagItem)
						print("end")
						
					}
				}
			}
			
			DispatchQueue.main.sync
				{

				}
			}
		}
	
//	let recogURL = URL(string: "https://unsplash.it/50/100?image=\(randumNumber)")!
//		visualRecognition.classify(image: recogURL.absoluteString, failure: failure) {
//			classifiedImages in
//			if let classifiedImage = classifiedImages.images.first {
//				print(classifiedImage.classifiers)
//
//				if let classification = classifiedImage.classifiers.first?.classes.first?.classification {
//					DispatchQueue.main.async {
//						self.navigationItem.title = classification
//						button.isEnabled = true
//					}
//
//				}
//			}else{
//				DispatchQueue.main.async {
//					self.navigationItem.title = "could not be determined"
//					button.isEnabled = true
//				}
//			}
//		}
//	}

    @IBAction func captureButtonPressed(_ sender: UIButton) {
        didPressTakePhoto()
		
    }












}

