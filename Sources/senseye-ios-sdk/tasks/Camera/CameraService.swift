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

    @Published var frame: CGImage?
    @Published var shouldSetupCaptureSession: Bool = false
    @Published var shouldShowCameraPermissionsDeniedAlert: Bool = false
    @AppStorage("username") var username: String = ""
    
    @Published var startedCameraRecording: Bool = false
    
    private let fileDestUrl: URL? = FileManager.default.urls(for: .documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first
    private var surveyInput : [String: String] = [:]
    private var latestFileUrl: URL?
    private var frameTimestampsForTask: [Int64] = []
    
    init(frontCameraDevice: CameraRepresentable = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)!, authenticationService: AuthenticationServiceProtocol, fileUploadService: FileUploadAndPredictionServiceProtocol) {
        self.frontCameraDevice = frontCameraDevice
        self.authenticationService = authenticationService
        self.fileUploadService = fileUploadService
        if let cameraInfo = frontCameraDevice as? AVCaptureDevice {
            let cameraType = cameraInfo.deviceType.rawValue
            fileUploadService.createSessionJsonFileAndStoreCognitoUserAttributes(surveyInput: ["cameraType": cameraType])
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
            self.captureSession.startRunning()
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
            Log.error("Error from \(#function). Unable to set device format")
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

@available(iOS 14.0, *)
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
                
                Log.info("time calc from buffer output -> \(outputBufferTimestampAsMillis)")
                frameTimestampsForTask.append(outputBufferTimestampAsMillis)
                if (!startedCameraRecording) {
                    DispatchQueue.main.async {
                        self.startedCameraRecording = true
                    }
                }
            }
        }
        
    }
    
}

@available(iOS 14.0, *)
extension CameraService {
    private func canWrite() -> Bool {
        return startedTaskRecording
            && videoWriter != nil
            && videoWriter.status == .writing
    }
    private func setupTaskRecordingToStart(onComplete: () -> Void) {
        guard !startedTaskRecording else { return }
        startedTaskRecording = true
        sessionAtSourceTime = nil
        onComplete()
    }
    
    func stopCurrentTaskRecordingAndSaveFile(onComplete: @escaping () -> Void) {
        guard startedTaskRecording else { return }
        startedTaskRecording = false
        videoWriter.finishWriting { [weak self] in 
            self?.sessionAtSourceTime = nil
            guard let url = self?.videoWriter.outputURL else { return }
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
