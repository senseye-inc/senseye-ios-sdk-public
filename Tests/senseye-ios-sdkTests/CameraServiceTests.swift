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
    
    func testSetupCaptureSession() {
        // given
        sut.checkPermissions()
        mockAVCaptureDevice.authorizationStatus = .notDetermined
        let exp = expectation(description: #function)
        
        // when
        sut.frontCameraDevice.requestAccessForVideo { returnedBool in
            // then
            XCTAssertTrue(self.mockAVCaptureDevice.requestAccessCalled)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }

}
