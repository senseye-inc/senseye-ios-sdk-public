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

@MainActor class CameraServiceTests: XCTestCase {
    
    var cameraService: CameraService!
    var mockAVCaptureDevice: MockAVCaptureDevice!
    var mockAuthenticationService: MockAuthenticationService!
    var mockFileUploadService: MockFileUploadAndPredictionService!
    
    @MainActor override func setUpWithError() throws {
        try super.setUpWithError()
        mockAuthenticationService = MockAuthenticationService()
        mockAVCaptureDevice = MockAVCaptureDevice()
        mockFileUploadService = MockFileUploadAndPredictionService()
        cameraService = CameraService(frontCameraDevice: mockAVCaptureDevice, authenticationService: mockAuthenticationService, fileUploadService: mockFileUploadService)
    }
    
    @MainActor override func tearDownWithError() throws {
        cameraService = nil
        mockAuthenticationService = nil
        mockAVCaptureDevice = nil
        try super.tearDownWithError()
    }
    
    func testCameraOnVideoAuthorizationStatusNotDetermined() {
        mockAVCaptureDevice.videoAuthorizationStatus = .notDetermined
        
        cameraService.start()
        
        XCTAssertTrue(mockAVCaptureDevice.requestAccessCalled)
        XCTAssertEqual(mockAVCaptureDevice.videoAuthorizationStatus, .notDetermined)
    }
    
    func testCameraOnVideoAuthorizationStatusAuthorized() {
        mockAVCaptureDevice.videoAuthorizationStatus = .authorized
        
        cameraService.start()
        
        XCTAssertFalse(mockAVCaptureDevice.requestAccessCalled)
        XCTAssertEqual(mockAVCaptureDevice.videoAuthorizationStatus, .authorized)
    }
    
    func testCaptureSessionPresetIsHigh() {
        mockAVCaptureDevice.videoAuthorizationStatus = .authorized
        
        cameraService.start()
        
        XCTAssertEqual(cameraService.captureSession.sessionPreset, .high)
    }
    
    func testAuthorizedShouldEnableStartSessionButton() {
        cameraService.shouldSetupCaptureSession = false
        mockAVCaptureDevice.videoAuthorizationStatus = .authorized
        
        cameraService.start()
        
        XCTAssertTrue(cameraService.shouldSetupCaptureSession)
    }
    
    func testDeniedShouldDisableStartSessionButton() {
        cameraService.shouldSetupCaptureSession = false
        mockAVCaptureDevice.videoAuthorizationStatus = .denied
        
        cameraService.start()
        
        XCTAssertFalse(cameraService.shouldSetupCaptureSession)
    }
    
}
