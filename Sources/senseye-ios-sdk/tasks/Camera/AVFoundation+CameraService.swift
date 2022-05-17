//
//  File.swift
//  
//
//  Created by Frank Oftring on 5/12/22.
//

import Foundation
import AVFoundation

protocol CameraRepresentable {
    var videoAuthorizationStatus: AVAuthorizationStatus { get set }
    func requestAccessForVideo(completion: @escaping (Bool) -> Void)
}

extension AVCaptureDevice: CameraRepresentable {
    
    var videoAuthorizationStatus: AVAuthorizationStatus {
        get {
            AVCaptureDevice.authorizationStatus(for: .video)
        } set { }
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
    
    func requestAccessForVideo(completion: @escaping (Bool) -> Void) {
        requestAccessCalled = true
        completion(requestAccessCalled)
    }
}

