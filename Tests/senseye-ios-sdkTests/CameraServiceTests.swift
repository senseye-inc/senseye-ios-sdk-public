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
    
    var sut: CameraService!
    var mockAVCaptureDevice: MockAVCaptureDevice!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        mockAVCaptureDevice = MockAVCaptureDevice()
    }
    
    override func tearDownWithError() throws {
        sut = nil
        mockAVCaptureDevice = nil
        try super.tearDownWithError()
    }
    
    func testCheckPermissionsCalledOnNotDetermined() {
        // given
        mockAVCaptureDevice.videoAuthorizationStatus = .notDetermined
        sut = CameraService(frontCameraDevice: mockAVCaptureDevice)
        
        // when
        sut.checkPermissions()
        
        // then
        XCTAssertTrue(self.mockAVCaptureDevice.requestAccessCalled)
    }
    
    func testCheckPermissionsNotCalledOnAuthorized() {
        // given
        mockAVCaptureDevice.videoAuthorizationStatus = .authorized
        sut = CameraService(frontCameraDevice: mockAVCaptureDevice)
        
        // when
        sut.checkPermissions()
        
        //then
        XCTAssertFalse(self.mockAVCaptureDevice.requestAccessCalled)
    }
    
    func testCaptureSessionPresetIsHigh() {
        // given
        mockAVCaptureDevice.videoAuthorizationStatus = .authorized
        sut = CameraService(frontCameraDevice: mockAVCaptureDevice)
        
        // when
        sut.setupCaptureSession()
        
        //then
        XCTAssertEqual(sut.captureSession.sessionPreset, .high)
    }
    
}
