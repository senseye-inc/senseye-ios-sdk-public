//
//  CameraService.swift
//
//
//  Created by Frank Oftring on 5/6/22.
//

import Foundation
import AVFoundation
import UIKit
import SwiftUI
import SwiftyJSON

@available(iOS 14.0, *)
@MainActor
class CameraService: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate, ObservableObject {
    
    private var captureOutput = AVCaptureVideoDataOutput()
    private var captureMovieFileOutput = AVCaptureMovieFileOutput()
    private var frontCameraDevice: CameraRepresentable
    private(set) var captureSession = AVCaptureSession()
    private let authenticationService: AuthenticationServiceProtocol
    private let fileUploadService: FileUploadAndPredictionServiceProtocol

    @Published var shouldSetupCaptureSession: Bool = false
    @Published var shouldShowCameraPermissionsDeniedAlert: Bool = false
    @AppStorage("username") var username: String = ""
    
    private let fileDestUrl: URL? = FileManager.default.urls(for: .documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first
    private var surveyInput : [String: String] = [:]
    
    private var latestFileUrl: URL?
    
    init(frontCameraDevice: CameraRepresentable = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)!, authenticationService: AuthenticationServiceProtocol, fileUploadService: FileUploadAndPredictionServiceProtocol) {
        self.frontCameraDevice = frontCameraDevice
        self.authenticationService = authenticationService
        self.fileUploadService = fileUploadService
        if let cameraInfo = frontCameraDevice as? AVCaptureDevice {
            let deviceType = cameraInfo.deviceType.rawValue
            fileUploadService.createSessionJsonFileAndStoreCognitoUserAttributes(surveyInput: ["cameraType": deviceType])
        }
    }
    
    func start() {
        self.checkPermissions()
    }
    
    private func checkPermissions() {
        switch frontCameraDevice.videoAuthorizationStatus {
        case .authorized: // The user has previously granted access to the camera.
            self.setupCaptureSession()
        case .notDetermined: // The user has not yet been asked for camera access.
            frontCameraDevice.requestAccessForVideo { granted in
                guard granted else {
                    self.shouldShowCameraPermissionsDeniedAlert = true
                    return
                }
                self.setupCaptureSession()
            }
        case .denied: // The user has previously denied access.
            shouldShowCameraPermissionsDeniedAlert = true
        case .restricted: // The user can't grant access due to restrictions.
            return
        @unknown default:
            break
        }
    }
    
    private func setupCaptureSession() {
        DispatchQueue.main.async {
            self.shouldSetupCaptureSession = true
        }
        guard let frontCameraDevice = (frontCameraDevice as? AVCaptureDevice) else {
            Log.error("Error casting cameraRepresentable to AvCaptureDevice")
            captureSession.commitConfiguration()
            return
        }
        
        do {
            self.configureCameraForHighestFrameRate(device: frontCameraDevice)

            captureSession.beginConfiguration()
            let videoDeviceInput = try AVCaptureDeviceInput(device: frontCameraDevice)
            if captureSession.canAddInput(videoDeviceInput) {
                captureSession.addInput(videoDeviceInput)
            }

            captureSession.sessionPreset = .high

            if captureSession.canAddOutput(captureOutput), captureSession.canAddOutput(captureMovieFileOutput) {
                captureSession.addOutput(captureOutput)
                captureSession.addOutput(captureMovieFileOutput)
            }
            let videoQueue = DispatchQueue(label: "videoQueue", qos: .userInteractive)
            captureOutput.setSampleBufferDelegate(self, queue: videoQueue)
            captureSession.commitConfiguration()
        } catch {
            Log.error("videoDeviceInput error")
        }
    }
    
    func setupVideoPreviewLayer(for cameraPreview: UIView) {
        var videoPreviewLayer = AVCaptureVideoPreviewLayer()
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        videoPreviewLayer.connection?.videoOrientation = .portrait
        videoPreviewLayer.frame.size =  cameraPreview.frame.size
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.connection?.videoOrientation = .portrait
        cameraPreview.layer.addSublayer(videoPreviewLayer)
        self.captureSession.startRunning()
    }
    
    private func configureCameraForHighestFrameRate(device: AVCaptureDevice) {
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
            Log.error("Capture Device format is nil for \(device).\n bestFormat: \(String(describing: bestFormat))/n bestFrameRate: \(String(describing: bestFrameRateRange))")
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
            Log.error("Error from \(#function). Unable to set device format")
        }
    }

    func startRecordingForTask(taskId: String) {
        let currentTimeStamp = Date().currentTimeMillis()
        guard let fileUrl = fileDestUrl?.appendingPathComponent("\(self.username)_\(currentTimeStamp)_\(taskId).mp4") else {
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
        Log.info("Capture session stopped")
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        Log.info("Video output finish \(outputFileURL.absoluteString)")
        latestFileUrl = outputFileURL
    }
    
    func uploadLatestFile() {
        if latestFileUrl != nil {
            fileUploadService.uploadData(fileUrl: latestFileUrl!)
            latestFileUrl = nil
        }
    }
    
    func clearLatestFileRecording() {
        latestFileUrl = nil
    }

    func goToSettings() {
        let settingsAppURL = URL(string: UIApplication.openSettingsURLString)!
        UIApplication.shared.open(settingsAppURL, options: [:], completionHandler: nil)
    }
}
