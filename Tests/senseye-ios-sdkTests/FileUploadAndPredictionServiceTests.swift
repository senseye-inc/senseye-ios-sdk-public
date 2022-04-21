//
//  FileUploadAndPredictionServiceTests.swift
//  senseye-ios-sdkTests
//
//  Created by Frank Oftring on 4/21/22.
//

import XCTest
@testable import senseye_ios_sdk

class FileUploadAndPredictionServiceTests: XCTestCase {
    
    var sut: FileUploadAndPredictionService!

    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = FileUploadAndPredictionService()
    }

    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }

}
