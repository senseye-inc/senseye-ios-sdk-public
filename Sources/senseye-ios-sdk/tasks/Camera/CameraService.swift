//
//  CameraService.swift
//
//
//  Created by Frank Oftring on 5/6/22.
//

import Foundation
import AVFoundation
import UIKit
@available(iOS 12, *)


@available(iOS 12, *)
class CameraService: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var videoPreviewLayer = AVCaptureVideoPreviewLayer()
    var captureSession = AVCaptureSession()
    var captureOutput = AVCaptureVideoDataOutput()
    var captureMovieFileOutput = AVCaptureMovieFileOutput()
    var frontCameraDevice: CameraRepresentable
    
    init(frontCameraDevice: CameraRepresentable = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)!) {
        self.frontCameraDevice = frontCameraDevice
    }
    
    func start() {
        checkPermissions()
    }
    
    func checkPermissions() {
        switch frontCameraDevice.authorizationStatus {
        case .authorized: // The user has previously granted access to the camera.
            self.setupCaptureSession()
        case .notDetermined: // The user has not yet been asked for camera access.
            frontCameraDevice.requestAccessForVideo { granted in
                guard granted else { return }
                self.setupCaptureSession()
            }
        case .denied: // The user has previously denied access.
            return
        case .restricted: // The user can't grant access due to restrictions.
            return
        @unknown default:
            break
        }
    }
    
    func setupCaptureSession() {
        
        guard let frontCameraDevice = (frontCameraDevice as? AVCaptureDevice) else {
            print("Error cast cameraRepresentable to AvCaptureDevice")
            return
        }
        configureCameraForHighestFrameRate(device: frontCameraDevice)
        
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            
            self.captureSession.beginConfiguration()
            guard let videoDeviceInput = try? AVCaptureDeviceInput(device: self.frontCameraDevice as! AVCaptureDevice), captureSession.canAddInput(videoDeviceInput) else {
                print("videoDeviceInput error")
                return
            }
            self.captureSession.addInput(videoDeviceInput)
            self.captureSession.sessionPreset = .high
            self.captureSession.addOutput(self.captureOutput)
            self.captureSession.addOutput(self.captureMovieFileOutput)
            let videoQueue = DispatchQueue(label: "videoQueue", qos: .userInteractive)
            self.captureOutput.setSampleBufferDelegate(self, queue: videoQueue)
            self.captureSession.commitConfiguration()
        }
    }
    
    func setupVideoPreviewLayer(for cameraPreview: UIView) {
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.connection?.videoOrientation = .portrait
        videoPreviewLayer.frame.size =  cameraPreview.frame.size
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.connection?.videoOrientation = .portrait
        cameraPreview.layer.addSublayer(videoPreviewLayer)
        captureSession.startRunning()
    }
    
    func configureCameraForHighestFrameRate(device: AVCaptureDevice) {
        
        var bestFormat: AVCaptureDevice.Format?
        var bestFrameRateRange: AVFrameRateRange?
        
        for format in device.formats {
            for range in format.videoSupportedFrameRateRanges {
                if range.maxFrameRate > bestFrameRateRange?.maxFrameRate ?? 0 {
                    bestFormat = format
                    bestFrameRateRange = range
                }
            }
        }
        
        if let bestFormat = bestFormat,
           let bestFrameRateRange = bestFrameRateRange {
            do {
                try device.lockForConfiguration()
                
                // Set the device's active format.
                device.activeFormat = bestFormat
                
                // Set the device's min/max frame duration.
                let duration = bestFrameRateRange.minFrameDuration
                device.activeVideoMinFrameDuration = duration
                device.activeVideoMaxFrameDuration = duration
                
                device.unlockForConfiguration()
            } catch {
                // Handle error.
                print("Error from \(#function)")
            }
        }
    }
}
