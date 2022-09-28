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
import Combine

@MainActor
class CameraService: NSObject, ObservableObject {
    
    private var captureVideoDataOutput = AVCaptureVideoDataOutput()
    private var frontCameraDevice: CameraRepresentable
    private(set) var captureSession = AVCaptureSession()
    private var startedTaskRecording = false
    private var videoWriter: AVAssetWriter!
    private var videoWriterInput: AVAssetWriterInput!
    private var sessionAtSourceTime: CMTime?
    private var startOfTaskMillis: Int64?
    
    private let authenticationService: AuthenticationServiceProtocol
    private let fileUploadService: FileUploadAndPredictionServiceProtocol
    
    var isSimulatorEnabled: Bool {
        frontCameraDevice.cameraType == .simulator
    }

    @Published var frame: CGImage?
    @Published var shouldSetupCaptureSession: Bool = false
    @Published var shouldShowCameraPermissionsDeniedAlert: Bool = false
    @Published var startedCameraRecording: Bool = false
    @Published var isCompliantInCurrentFrame: Bool = false
    @Published var currentComplianceInfo: FacialComplianceStatus = FacialComplianceStatus(statusMessage: "Uh oh not quite, move your face into the frame.", statusIcon: "xmark.circle", statusBackgroundColor: .red)
    
    @AppStorage("username") var username: String = ""
    
    private let fileDestUrl: URL? = FileManager.default.urls(for: .documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first
    private var surveyInput : [String: String] = [:]
    private var latestFileUrl: URL?
    private var frameTimestampsForTask: [Int64] = []
    
    private var cameraComplianceViewModel = CameraComplianceViewModel()
    
    var cancellables = Set<AnyCancellable>()
    
    init(authenticationService: AuthenticationServiceProtocol, fileUploadService: FileUploadAndPredictionServiceProtocol) {
        if let realCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            self.frontCameraDevice = realCameraDevice
        } else {
            self.frontCameraDevice = MockAVCaptureDevice()
        }
        self.authenticationService = authenticationService
        self.fileUploadService = fileUploadService
        if let cameraInfo = frontCameraDevice as? AVCaptureDevice {
            let cameraType = cameraInfo.deviceType.rawValue
            fileUploadService.createSessionJsonFileAndStoreCognitoUserAttributes(surveyInput: ["cameraType": cameraType])
        }
        super.init()
        addSubscribers()
    }
    
    private func addSubscribers() {
        cameraComplianceViewModel.$faceDetectionResult
            .receive(on: DispatchQueue.main)
            .sink { updatedCompliance in
                Log.info("setting the updated compliance in cameraservice")
                self.currentComplianceInfo = updatedCompliance
            }
            .store(in: &cancellables)
    }
    
    func start() {
        if isSimulatorEnabled {
            simulateStart()
            return
        }
        self.checkPermissions()
        self.startedCameraRecording = false
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
            Log.info("Using Camera representable for AVCaptureDevice")
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


            if captureSession.canAddOutput(captureVideoDataOutput) {
                captureSession.addOutput(captureVideoDataOutput)
                Log.info("added all the output sessions")
            }
            let videoOutputQueue = DispatchQueue(label: "videoOutputQueue")
            captureVideoDataOutput.setSampleBufferDelegate(self, queue: videoOutputQueue)
            guard let connection = captureVideoDataOutput.connection(with: AVFoundation.AVMediaType.video) else { return }
            guard connection.isVideoOrientationSupported else { return }
            guard connection.isVideoMirroringSupported else { return }
            connection.videoOrientation = .portrait
            connection.isVideoMirrored = true
            captureSession.commitConfiguration()
            DispatchQueue.global(qos: .background).async {
                Task {
                    await self.captureSession.startRunning()
                }
            }
        } catch {
            Log.error("videoDeviceInput error")
        }
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
            Log.error("Unable to set device format", shouldLogContext: true)
        }
    }

    func startRecordingForTask(taskId: String) {
        let currentTimeStamp = Date().currentTimeMillis()
        guard let fileUrl = fileDestUrl?.appendingPathComponent("\(self.username)_\(currentTimeStamp)_\(taskId).mp4") else {
            return
        }
        setupTaskRecordingToStart() {
            self.setupWriter(url: fileUrl)
        }
    }
    
    func stopRecording() {
        if isSimulatorEnabled {
            simulateStopCurrentTaskRecordingAndSaveFile()
            return
        }
        self.stopCurrentTaskRecordingAndSaveFile() {
            self.captureSession.stopRunning()
        }
    }
    
    func stopCaptureSession() {
        self.captureSession.stopRunning()
        Log.info("Capture session stopped")
    }
    
    func uploadLatestFile() {
        if latestFileUrl != nil {
            fileUploadService.uploadData(fileUrl: latestFileUrl!)
            latestFileUrl = nil
            frameTimestampsForTask = []
        }
    }
    
    func clearLatestFileRecording() {
        latestFileUrl = nil
    }

    func goToSettings() {
        let settingsAppURL = URL(string: UIApplication.openSettingsURLString)!
        UIApplication.shared.open(settingsAppURL, options: [:], completionHandler: nil)
    }
    
    private func setupWriter(url: URL) {
      do {
          videoWriter = try AVAssetWriter(url: url, fileType: AVFileType.mp4)
          
          videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: [
                  AVVideoCodecKey: AVVideoCodecType.h264,
                  AVVideoWidthKey: 1080,
                  AVVideoHeightKey: 1920,
              ])
          videoWriterInput.expectsMediaDataInRealTime = true
          if videoWriter.canAdd(videoWriterInput) {
              videoWriter.add(videoWriterInput)
          }
          
          videoWriter.startWriting()
      }
      catch let error {
          Log.error("Video Writer error --> \(error.localizedDescription)")
      }
    }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    internal func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    
        let writable = canWrite()
        
        //Task has not started --> Display Camera Preview frames
        guard writable else {
            //Use latest image for preview
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            let ciImage = CIImage(cvPixelBuffer: imageBuffer)
            let context = CIContext()
            DispatchQueue.main.async {
                self.frame = context.createCGImage(ciImage, from: ciImage.extent)
            }
            cameraComplianceViewModel.runImageDetection(sampleBuffer: sampleBuffer)
            return
        }
        
        //Task has started --> start up the VideoWriter
        if writable, sessionAtSourceTime == nil {
            sessionAtSourceTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            startOfTaskMillis = Date().currentTimeMillis()
            videoWriter.startSession(atSourceTime: sessionAtSourceTime!)
            Log.info("frame output on recording.. writing was started)")
        }

        //Task is ongoing --> start writing buffers to VideoWriter
        if output == captureVideoDataOutput {
            if videoWriterInput.isReadyForMoreMediaData {
                videoWriterInput.append(sampleBuffer)
                guard let sourceTime = sessionAtSourceTime, let startTaskTime = startOfTaskMillis else {
                    return
                }
                let bufferTimestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                let diffOfBufferAndSessionStart = CMTimeSubtract(bufferTimestamp, sourceTime)
                let diffInMillis = Int64((CMTimeGetSeconds(diffOfBufferAndSessionStart)*1000))
                let outputBufferTimestampAsMillis = startTaskTime + diffInMillis
                
                frameTimestampsForTask.append(outputBufferTimestampAsMillis)
                if (!startedCameraRecording) {
                    if isSimulatorEnabled { return }
                    DispatchQueue.main.async {
                        self.startedCameraRecording = true
                    }
                }
            }
        }
        
    }
    
}

extension CameraService {
    private func canWrite() -> Bool {
        return startedTaskRecording
            && videoWriter != nil
            && videoWriter.status == .writing
    }
    private func setupTaskRecordingToStart(onComplete: () -> Void) {
        if isSimulatorEnabled {
            simulatSetupTaskRecordingToStart()
            return
        }
        guard !startedTaskRecording else {
            Log.error("startedTaskRecording is false", shouldLogContext: true)
            return
        }
        startedTaskRecording = true
        sessionAtSourceTime = nil
        onComplete()
    }
    
    func stopCurrentTaskRecordingAndSaveFile(onComplete: @escaping () -> Void) {
        guard startedTaskRecording else {
            Log.error("startedTaskRecording is false", shouldLogContext: true)
            return
        }
        startedTaskRecording = false
        startedCameraRecording = false
        videoWriter.finishWriting { [weak self] in
            self?.sessionAtSourceTime = nil
            guard let url = self?.videoWriter.outputURL else {
                Log.error("self?.videoWriter.outputURL is nil", shouldLogContext: true)
                return
            }
            Log.info("Video output finish --> \(url.absoluteString)")
            self?.latestFileUrl = url
            self?.fileUploadService.setLatestFrameTimestampArray(frameTimestamps: self?.frameTimestampsForTask)
            onComplete()
        }
    }
    
    func getLatestUrl() -> URL {
        return self.latestFileUrl ?? URL(fileURLWithPath: "")
    }
}

// MARK: - Simulator
extension CameraService {
    
    fileprivate func simulateStart() {
        shouldSetupCaptureSession = true
        startedCameraRecording = false
        return
    }
    
    fileprivate func simulateStartCameraRecording() {
        Log.info("in \(#function)-----")
        //Handle mock-camera call
        DispatchQueue.main.async {
            self.startedCameraRecording = true
        }
    }
    
    fileprivate func simulatSetupTaskRecordingToStart() {
        simulateStartCameraRecording()
        Log.info("in \(#function)-----")
        guard !startedTaskRecording else {
            Log.error("startedTaskRecording is false", shouldLogContext: true)
            return
        }
        startedTaskRecording = true
        sessionAtSourceTime = nil
    }

    fileprivate func simulateStopCurrentTaskRecordingAndSaveFile() {
        Log.info("in \(#function)-----")
        guard startedTaskRecording else {
            Log.error("startedTaskRecording is false", shouldLogContext: true)
            return
        }
        startedTaskRecording = false
        startedCameraRecording = false
    }
    
    
}
