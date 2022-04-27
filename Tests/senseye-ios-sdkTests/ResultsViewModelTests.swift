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
//        fileUploadService.reset()
        fileUploadService = nil
        sdk = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Configuration Tests
    
    func testMockJSONDecoding() {
        let predictionResult = fileUploadService.decodeResponse()
        XCTAssertNotNil(predictionResult)
    }
    
    func testAmplifyIsConfigured() {
        let configuration = Amplify.isConfigured
        XCTAssertTrue(configuration)
    }
    
    // MARK: - Default State
    
    func testIsLoadingBeginsFalse() {
        XCTAssertFalse(sut.isLoading)
    }
    
    func testErrorIsNil(){
        XCTAssertNil(sut.error)
    }
    
    
    // MARK: - startPredictionForCurrentSessionUploads
    
    func testWhenStartPreditionsIsLoadingEqualsTrue() {
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
    
    func testGetPredictionResponseFailure() {
        // Given
        fileUploadService.shouldReturnError = true

        // When
        sut.getPredictionResponse()
        XCTAssert(sut.predictionStatus == "Starting predictions...")
        print(sut.error?.localizedDescription)

        // Then
//        XCTAssertNotNil(sut.error)
    }
    
    func testFunctionWasCalled() {
        // Given
        fileUploadService.startPredictionForCurrentSessionUploadsWasCalled = false

        // When
        sut.getPredictionResponse()

        // Then
        XCTAssert(fileUploadService.startPredictionForCurrentSessionUploadsWasCalled == true)
    }

}
