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
        sut = CameraService(frontCameraDevice: mockAVCaptureDevice)
    }
    
    override func tearDownWithError() throws {
        sut = nil
        mockAVCaptureDevice = nil
        try super.tearDownWithError()
    }
    
    func testCheckPermissionsCalledOnNotDetermined() {
        // given
        sut.frontCameraDevice.videoAuthorizationStatus = .notDetermined

        // when
        sut.checkPermissions()
        
        // then
        XCTAssertTrue(self.mockAVCaptureDevice.requestAccessCalled)
    }
    
    func testCheckPermissionsNotCalledOnAuthorized() {
        // given
        sut.frontCameraDevice.videoAuthorizationStatus = .authorized
        
        // when
        sut.checkPermissions()
        
        //then
        XCTAssertFalse(self.mockAVCaptureDevice.requestAccessCalled)
    }
}
