//
//  CameraServiceTests.swift
//  
//
//  Created by Frank Oftring on 5/11/22.
//

import XCTest
import CoreMotion
@testable import senseye_ios_sdk
import AVFoundation

@available(iOS 12, *)
class CameraServiceTests: XCTestCase {
    
    var cameraService: CameraService!
    var mockAVCaptureDevice: MockAVCaptureDevice!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        mockAVCaptureDevice = MockAVCaptureDevice()
    }
    
    override func tearDownWithError() throws {
        cameraService = nil
        mockAVCaptureDevice = nil
        try super.tearDownWithError()
    }
    
    func testCameraOnVideoAuthorizationStatusNotDetermined() {
        mockAVCaptureDevice.videoAuthorizationStatus = .notDetermined
        cameraService = CameraService(frontCameraDevice: mockAVCaptureDevice)
        
        cameraService.checkPermissions()
        
        XCTAssertTrue(mockAVCaptureDevice.requestAccessCalled)
        XCTAssertEqual(mockAVCaptureDevice.videoAuthorizationStatus, .notDetermined)
    }
    
    func testCameraOnVideoAuthorizationStatusAuthorized() {
        mockAVCaptureDevice.videoAuthorizationStatus = .authorized
        cameraService = CameraService(frontCameraDevice: mockAVCaptureDevice)
        
        cameraService.checkPermissions()
        
        XCTAssertFalse(mockAVCaptureDevice.requestAccessCalled)
        XCTAssertEqual(mockAVCaptureDevice.videoAuthorizationStatus, .authorized)
    }
    
    func testCaptureSessionPresetIsHigh() {
        mockAVCaptureDevice.videoAuthorizationStatus = .authorized
        cameraService = CameraService(frontCameraDevice: mockAVCaptureDevice)
        
        cameraService.setupCaptureSession()
        
        XCTAssertEqual(cameraService.captureSession.sessionPreset, .high)
    }
    
}
