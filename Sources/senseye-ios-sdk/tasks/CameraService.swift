//
//  CameraService.swift
//
//
//  Created by Frank Oftring on 5/6/22.
//

import Foundation
import AVFoundation

class CameraSevice: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    let previewLayer = AVCaptureVideoPreviewLayer()
    
    var captureSession = AVCaptureSession()
    var captureOutput = AVCaptureVideoDataOutput()
    var captureMovieFileOutput = AVCaptureMovieFileOutput()
    var frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
    
    func start(completion: @escaping (Error?) -> ()) {
        checkPermissions(completion: completion)
    }
    
    private func checkPermissions(completion: @escaping (Error?) -> ()) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard granted else { return }
                DispatchQueue.main.async {
                    self?.setupCamera(completion: completion)
                }
            }
        case .restricted:
            break
        case .denied:
            break
        case .authorized:
            setupCamera(completion: completion)
        @unknown default:
            break
        }
    }
    
    func setupCamera(completion: @escaping (Error?) -> ()) {
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            guard let videoDeviceInput = try? AVCaptureDeviceInput(device: self.frontCameraDevice!) else {
                print("videoDeviceInput error")
                return
            }
            self.captureSession.addInput(videoDeviceInput)
            self.captureSession.sessionPreset = AVCaptureSession.Preset.high
            self.captureSession.addOutput(self.captureOutput)
            self.captureSession.addOutput(self.captureMovieFileOutput)
            let videoQueue = DispatchQueue(label: "videoQueue", qos: .userInteractive)
            self.captureOutput.setSampleBufferDelegate(self, queue: videoQueue)
            self.captureSession.beginConfiguration()
            self.captureSession.commitConfiguration()
        }
    }
    
}
