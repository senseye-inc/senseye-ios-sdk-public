//
//  File.swift
//  
//
//  Created by Frank Oftring on 5/12/22.
//

import Foundation
import AVFoundation

enum BuildCameraType {
    case simulator
    case device
}

protocol CameraRepresentable {
    var cameraType: BuildCameraType { get }
    var videoAuthorizationStatus: AVAuthorizationStatus { get }
    func requestAccessForVideo(completion: @escaping (Bool) -> Void)
}

extension AVCaptureDevice: CameraRepresentable {
    
    var videoAuthorizationStatus: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }
    var cameraType: BuildCameraType {
        .device
    }
    
    func requestAccessForVideo(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            completion(granted)
        }
    }
}

final class MockAVCaptureDevice: CameraRepresentable {
    
    var requestAccessCalled: Bool = false
    var videoAuthorizationStatus: AVAuthorizationStatus = .notDetermined
    var cameraType: BuildCameraType = .simulator
    
    func requestAccessForVideo(completion: @escaping (Bool) -> Void) {
        requestAccessCalled = true
        completion(requestAccessCalled)
    }
}

