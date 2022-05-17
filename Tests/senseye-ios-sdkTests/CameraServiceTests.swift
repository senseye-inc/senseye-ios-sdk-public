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
    
    func testCheckPermissionsCalledOnNotDetermined() {
        mockAVCaptureDevice.videoAuthorizationStatus = .notDetermined
        cameraService = CameraService(frontCameraDevice: mockAVCaptureDevice)
        
        cameraService.checkPermissions()
        
        XCTAssertTrue(mockAVCaptureDevice.requestAccessCalled)
    }
    
    func testCheckPermissionsNotCalledOnAuthorized() {
        mockAVCaptureDevice.videoAuthorizationStatus = .authorized
        cameraService = CameraService(frontCameraDevice: mockAVCaptureDevice)
        
        cameraService.checkPermissions()
        
        XCTAssertFalse(mockAVCaptureDevice.requestAccessCalled)
    }
    
    func testCaptureSessionPresetIsHigh() {
        mockAVCaptureDevice.videoAuthorizationStatus = .authorized
        cameraService = CameraService(frontCameraDevice: mockAVCaptureDevice)
        
        cameraService.setupCaptureSession()
        
        XCTAssertEqual(cameraService.captureSession.sessionPreset, .high)
    }
    
}
