//
//  CameraService.swift
//
//
//  Created by Frank Oftring on 5/6/22.
//

import Foundation
import AVFoundation
import UIKit

@available(iOS 13.0, *)
@MainActor
class CameraService: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate, ObservableObject {
    
    private var captureOutput = AVCaptureVideoDataOutput()
    private var captureMovieFileOutput = AVCaptureMovieFileOutput()
    private var frontCameraDevice: CameraRepresentable
    private(set) var captureSession = AVCaptureSession()
    private let authenticationService: AuthenticationServiceProtocol
    private let fileUploadService: FileUploadAndPredictionService

    @Published var shouldSetupCaptureSession: Bool = false
    @Published var shouldShowCameraPermissionsDeniedAlert: Bool = false
    @Published var shouldDisplayPretaskTutorial: Bool = false
    
    private let fileDestUrl: URL? = FileManager.default.urls(for: .documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first
    private var surveyInput : [String: String] = [:]
    
    init(frontCameraDevice: CameraRepresentable = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)!, authenticationService: AuthenticationServiceProtocol, fileUploadService: FileUploadAndPredictionService) {
        self.frontCameraDevice = frontCameraDevice
        self.authenticationService = authenticationService
        self.fileUploadService = fileUploadService
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
            return
        }
        self.configureCameraForHighestFrameRate(device: frontCameraDevice)

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
            Log.error("Capture Device format is nil for \(device).\n bestFormat: \(bestFormat)/n bestFrameRate: \(bestFrameRateRange)")
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
        getSurveyResults()
        authenticationService.getUsername { [self] username in
            let currentTimeStamp = Date().currentTimeMillis()
            guard let fileUrl = fileDestUrl?.appendingPathComponent("\(username)_\(currentTimeStamp)_\(taskId).mp4") else {
                return
            }
            self.captureMovieFileOutput.startRecording(to: fileUrl, recordingDelegate: self)
        }
    }
    
    func stopRecording() {
        self.captureMovieFileOutput.stopRecording()
    }
    
    func startCaptureSession() {
        self.captureSession.startRunning()
    }

    func getSurveyResults() {
        let age = UserDefaults.standard.value(forKey: "selectedAge") as! Int
        let eyeColor = UserDefaults.standard.value(forKey: "selectedEyeColor") as! String
        let gender = UserDefaults.standard.value(forKey: "selectedGender") as! String
        surveyInput["age"] = String(age)
        surveyInput["gender"] = gender
        surveyInput["eyeColor"] = eyeColor
    }
    
    func stopCaptureSession() {
        self.captureSession.stopRunning()
        fileUploadService.createSessionInputJsonFile(surveyInput: surveyInput, tasks: [])
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("video output finish")
        print(outputFileURL.absoluteString)
        fileUploadService.uploadData(fileUrl: outputFileURL)
    }

    func goToSettings() {
        let settingsAppURL = URL(string: UIApplication.openSettingsURLString)!
        UIApplication.shared.open(settingsAppURL, options: [:], completionHandler: nil)
    }
}
