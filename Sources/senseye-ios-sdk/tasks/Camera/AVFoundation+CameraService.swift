//
//  File.swift
//  
//
//  Created by Frank Oftring on 5/12/22.
//

import Foundation
import AVFoundation
import UIKit

enum CameraRepresentableAuthorizationStatus : Int {
    case notDetermined  = 0
    case restricted     = 1
    case denied         = 2
    case authorized     = 3
}

// MARK: - Protocol for AVCaptureDevice

protocol CameraRepresentable {
    var cameraAuthorizedForVideo: Bool { get }
    var authorizationStatus: CameraRepresentableAuthorizationStatus { get set }
    func requestAccessForVideo(completion: @escaping (Bool) -> Void)
}

extension AVCaptureDevice: CameraRepresentable {
    var cameraAuthorizedForVideo: Bool {
        return AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }
    
    var authorizationStatus: CameraRepresentableAuthorizationStatus {
        get {
            CameraRepresentableAuthorizationStatus(rawValue: AVCaptureDevice.authorizationStatus(for: .video).rawValue)!
        } set {
            
        }
    }
    
    func requestAccessForVideo(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            completion(granted)
        }
    }
}

// MARK: - MockAVCaptureDevice

final class MockAVCaptureDevice: CameraRepresentable {
    
    var requestAccessCalled: Bool = false
    var cameraAuthorizedForVideo: Bool = true
    var authorizationStatus: CameraRepresentableAuthorizationStatus {
        get {
            .notDetermined
        } set {
            
        }
    }
    
    func requestAccessForVideo(completion: @escaping (Bool) -> Void) {
        requestAccessCalled = true
    }
}

// MARK: - Mock Camera Service

//protocol CameraServiceProtocol {
//    func start()
//    func setupVideoPreviewLayer(for cameraPreview: UIView)
//    var captureMovieFileOutput: AVCaptureMovieFileOutput { get set }
//    var captureSession: AVCaptureSession { get set }
//    func checkPermissions()
//}

//final class MockCameraService: CameraServiceProtocol {
//
//    let mockAVCaptureDevice = MockAVCaptureDevice()
//
//    func start() { }
//
//    func setupVideoPreviewLayer(for cameraPreview: UIView) { }
//
//    var captureMovieFileOutput = AVCaptureMovieFileOutput()
//
//    var captureSession = AVCaptureSession()
//
//    func checkPermissions() {
//        mockAVCaptureDevice.requestAccessForVideo { granted in
//
//        }
//    }
//
//}
