//
//  FaceDetectionViewController.swift
//  FaceDetection
//
//  Created by Yessen Yermukhanbet on 3/26/21.
//

import UIKit
import AVKit
import Vision

class FaceDetectionViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate {

    let numberOfFaces: UILabel = {
            let label = UILabel()
            label.backgroundColor = .clear
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textColor = .orange
            label.font = UIFont(name: "Avenir-Heavy", size: 30)
            label.text = "No face"
            return label
        }()
    lazy var tryAgainButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Try again", for: .normal)
        button.addTarget(self, action:#selector(resetView), for: .touchUpInside)
        return button
    }()
    lazy var takePicButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.5975484087)
        button.addTarget(self, action: #selector(handleTakePhoto), for: .touchUpInside)
        button.layer.masksToBounds = false
        button.layer.cornerRadius = 50
        button.isEnabled = false
        return button
    }()
    let imageView = UIImageView()
    let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
        setupCamera()
        imageView.frame = self.view.frame
        self.view.addSubview(imageView)
        imageView.isHidden = true
        setupLabel()
        self.view.addSubview(tryAgainButton)
        tryAgainButton.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 20).isActive = true
        tryAgainButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: 20).isActive = true
        self.view.addSubview(takePicButton)
        takePicButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        takePicButton.heightAnchor.constraint(equalToConstant: 100).isActive = true
        takePicButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -30).isActive = true
        takePicButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
    }
        
    func setupTabBar() {
        self.navigationController?.navigationBar.isHidden = true
    }
        
    fileprivate func setupCamera() {
            
        captureSession.sessionPreset = .high
        
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
            
        captureSession.addInput(input)
            
        captureSession.startRunning()
            
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = self.view.layer.bounds
            
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
        captureSession.addOutput(photoOutput)
        
    }
        
        fileprivate func setupLabel() {
            view.addSubview(numberOfFaces)
            numberOfFaces.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -32).isActive = true
            numberOfFaces.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
            numberOfFaces.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
            numberOfFaces.heightAnchor.constraint(equalToConstant: 80).isActive = true
        }
    @objc private func handleTakePhoto() {
        let photoSettings = AVCapturePhotoSettings()
        if let photoPreviewType = photoSettings.availablePreviewPhotoPixelFormatTypes.first {
            photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoPreviewType]
            photoOutput.capturePhoto(with: photoSettings, delegate: self)
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else { return }
        let previewImage = UIImage(data: imageData)
        captureSession.stopRunning()
        imageView.image = previewImage
        imageView.isHidden = false
//        let photoPreviewContainer = PhotoPreviewView(frame: self.view.frame)
//        photoPreviewContainer.photoImageView.image = previewImage
//        self.view.addSubviews(photoPreviewContainer)
    }
    @objc func resetView(_ sender: Any){
        imageView.image = nil
        imageView.isHidden = true
        captureSession.startRunning()
    }
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            
            guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            
            let request = VNDetectFaceRectanglesRequest { (req, err) in
                
                if let err = err {
                    print("Failed to detect faces:", err)
                    return
                }
                
                DispatchQueue.main.async {
                    if let results = req.results {
                        if results.count == 1{
                            self.takePicButton.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.7303848735)
                            self.takePicButton.isEnabled = true
                        }else{
                            self.takePicButton.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.1708684816)
                            self.takePicButton.isEnabled = false
                        }
                        self.numberOfFaces.text = "\(results.count) person(s)"
                    }
                }
            }
            DispatchQueue.global(qos: .userInteractive).async {
                let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
                do {
                    try handler.perform([request])
                } catch let reqErr {
                    print("Failed to perform request:", reqErr)
                }
            }
        }
}
