//
//  ResultsViewModelTests.swift
//  senseye-ios-sdkTests
//
//  Created by Frank Oftring on 4/22/22.
//

import XCTest
@testable import senseye_ios_sdk
@testable import Amplify
@testable import AWSS3StoragePlugin
@testable import AWSCognitoAuthPlugin

@available(iOS 15.0, *)
class ResultsViewModelTests: XCTestCase {
    
    var sut: ResultsViewModel!
    var fileUploadService: FileUploadAndPredictionServiceMock!
    var sdk: SenseyeSDK!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        sdk = SenseyeSDK()
        sdk.initializeSDK()
        if !Amplify.isConfigured {
            let configurationURL = URL(fileURLWithPath: "/Users/frank/Desktop/senseye-ios-sdk/Sources/senseye-ios-sdk/Resources/amplifyconfiguration.json")
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSS3StoragePlugin())
            try Amplify.configure(AmplifyConfiguration.init(configurationFile: configurationURL))
        }
        
        fileUploadService = FileUploadAndPredictionServiceMock()
        sut = ResultsViewModel(fileUploadService: fileUploadService)
    }
    
    override func tearDownWithError() throws {
        sut = nil
        fileUploadService = nil
        sdk = nil
        try super.tearDownWithError()
    }
    
    func testAmplifyIsConfigured() {
        let configuration = Amplify.isConfigured
        XCTAssertTrue(configuration)
    }
    
    func testIsLoadingBeginsFalse() {
        XCTAssertFalse(sut.isLoading)
    }
    
    func testStartPreditionsIsLoadingEqualsTrue() {
        // Given
        sut.isLoading = false
        
        // When
        sut.startPredictions()
        
        // Then
        XCTAssertTrue(sut.isLoading)
    }
    
    func testUpdatePredictionStatusWhenGetPredictionResponseIsCalled() {
        // Given
        sut.predictionStatus = "(Default Status)"
        
        // When
        sut.getPredictionResponse()
        
        // Then
        XCTAssertEqual(sut.predictionStatus, "Starting predictions...")
    }
    
    func testUpdatePredicitonStatusWhenPredictionResposneIsReturned() {
        // Given
//        let expectation = expectation(description: #function)
        
        // When
        sut.fileUploadService.startPredictionForCurrentSessionUploads { result in
            XCTAssertNotNil(result)
            print(result)
//            expectation.fulfill()
        }
        
        // Then
//        wait(for: [expectation], timeout: 10)
    }
    
}
