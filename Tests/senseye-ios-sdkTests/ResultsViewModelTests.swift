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
    
    
    // MARK: - startPredictions
    
    func testWhenStartPreditionsIsLoadingEqualsTrue() {
        // Given
        sut.isLoading = false
        
        // When
        sut.startPredictions()
        
        // Then
        XCTAssertTrue(sut.isLoading)
    }
    
    // MARK: - getPredictionResponse
    
    func testUpdatePredictionStatusWhenGetPredictionResponseIsCalled() {
        // Given
        sut.predictionStatus = "(Default Status)"
        
        // When
        sut.getPredictionResponse()
        
        // Then
        XCTAssertEqual(sut.predictionStatus, "Starting predictions...")
    }
    
    func testGetPredictionResponseCallsStartPredictionForCurrentSessionUploadsWasCalled() {
        sut.getPredictionResponse()
        XCTAssertTrue(self.fileUploadService.startPredictionForCurrentSessionUploadsWasCalled)
    }
    
    func testGetPredictionResponseSuccess() {
        let expectation = expectation(description: #function)
        let response = fileUploadService.decodeResponse()!
        fileUploadService.result = .success(response.id)
        
        sut.getPredictionResponse()
        
        DispatchQueue.main.async {
            XCTAssertEqual(self.sut.predictionStatus, "Prediction API request sent...")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }
    
    
    func testGetPredictionResponseFailure() {
        let expectation = expectation(description: #function)
        fileUploadService.result = .failure(MockFileUploadAndPredictionServiceError.startPredictionForCurrentSessionUploads)
        
        sut.getPredictionResponse()
        
        DispatchQueue.main.async {
            let errorType = (self.sut.error as? MockFileUploadAndPredictionServiceError) == .startPredictionForCurrentSessionUploads
            XCTAssertNotNil(self.sut.error)
            XCTAssertTrue(errorType)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2)
    }
    
    // MARK: - startPeriodicPredictions
    
    func testStartPeriodicPredictionsCallSstartPeriodicUpdatesOnPredictionIdWasCalled() {
        sut.startPeriodicPredictions()
        XCTAssertTrue(self.fileUploadService.startPeriodicUpdatesOnPredictionIdWasCalled)
    }
    
    func testStartPeriodicPredictionsSuccess() {
        let expectation = expectation(description: #function)
        let response = fileUploadService.decodeResponse()!

        fileUploadService.result = .success(response.status)
        
        sut.startPeriodicPredictions()
        
        DispatchQueue.main.async {
            let jobStatusAndResultResponse = response.status
            XCTAssertEqual(self.sut.predictionStatus, "Returned a result for prediction... \(jobStatusAndResultResponse)")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }
    
    
    func testStartPeriodicPredictionsFailure() {
        let expectation = expectation(description: #function)
        fileUploadService.result = .failure(MockFileUploadAndPredictionServiceError.startPeriodicUpdatesOnPredictionId)
        
        sut.getPredictionResponse()
        
        DispatchQueue.main.async {
            let errorType = (self.sut.error as? MockFileUploadAndPredictionServiceError) == .startPeriodicUpdatesOnPredictionId
            XCTAssertNotNil(self.sut.error)
            XCTAssertTrue(errorType)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2)
    }
}
