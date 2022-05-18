//
//  CameraService.swift
//
//
//  Created by Frank Oftring on 5/6/22.
//

import Foundation
import AVFoundation
import UIKit

protocol CameraServiceDelegate: AnyObject {
    func didFinishFileOutput(fileURL: URL)
    func showCameraAccessAlert()
}

class CameraService: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate {
    
    private var videoPreviewLayer = AVCaptureVideoPreviewLayer()
    private var captureOutput = AVCaptureVideoDataOutput()
    private var captureMovieFileOutput = AVCaptureMovieFileOutput()
    private var frontCameraDevice: CameraRepresentable
    private(set) var captureSession = AVCaptureSession()
    
    var cameraPermissionsAllowed: Bool {
        frontCameraDevice.videoAuthorizationStatus == .authorized
    }
    
    weak var delegate: CameraServiceDelegate?
    
    private let fileDestUrl: URL? = FileManager.default.urls(for: .documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first
    
    init(frontCameraDevice: CameraRepresentable = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)!) {
        self.frontCameraDevice = frontCameraDevice
    }
    
    func start() {
        checkPermissions()
    }
    
    private func checkPermissions() {
        switch frontCameraDevice.videoAuthorizationStatus {
        case .authorized: // The user has previously granted access to the camera.
            self.setupCaptureSession()
        case .notDetermined: // The user has not yet been asked for camera access.
            frontCameraDevice.requestAccessForVideo { granted in
                guard granted else {
                    self.delegate?.showCameraAccessAlert()
                    return
                }
                self.setupCaptureSession()
            }
        case .denied: // The user has previously denied access.
            delegate?.showCameraAccessAlert()
        case .restricted: // The user can't grant access due to restrictions.
            return
        @unknown default:
            break
        }
    }
    
    private func setupCaptureSession() {
        
        guard let frontCameraDevice = (frontCameraDevice as? AVCaptureDevice) else {
            print("Error casting cameraRepresentable to AvCaptureDevice")
            return
        }
        configureCameraForHighestFrameRate(device: frontCameraDevice)
        
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            
            captureSession.beginConfiguration()
            guard let videoDeviceInput = try? AVCaptureDeviceInput(device: frontCameraDevice), captureSession.canAddInput(videoDeviceInput) else {
                print("videoDeviceInput error")
                return
            }
            captureSession.addInput(videoDeviceInput)
            captureSession.sessionPreset = .high
            captureSession.addOutput(captureOutput)
            captureSession.addOutput(captureMovieFileOutput)
            let videoQueue = DispatchQueue(label: "videoQueue", qos: .userInteractive)
            captureOutput.setSampleBufferDelegate(self, queue: videoQueue)
            captureSession.commitConfiguration()
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
        cameraPreview.isHidden = false
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
        
        guard let bestFormat = bestFormat, let bestFrameRateRange = bestFrameRateRange else {
            print("Capture Device format is nil for \(device).\n bestFormat: \(bestFormat)/n bestFrameRate: \(bestFrameRateRange)")
            return
        }
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
            print("Error from \(#function). Unable to set device format")
        }
        
    }
    
    func startRecordingForTask(taskId: String) {
        let currentTimeStamp = Date().currentTimeMillis()
        guard let fileUrl = fileDestUrl?.appendingPathComponent("0000_\(currentTimeStamp)_\(taskId).mp4") else {
            return
        }
        self.captureMovieFileOutput.startRecording(to: fileUrl, recordingDelegate: self)
    }
    
    func stopRecording() {
        self.captureMovieFileOutput.stopRecording()
    }
    
    func startCaptureSession() {
        self.captureSession.startRunning()
    }
    
    func stopCaptureSession() {
        self.captureSession.stopRunning()
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        delegate?.didFinishFileOutput(fileURL: outputFileURL)
    }
    
}
