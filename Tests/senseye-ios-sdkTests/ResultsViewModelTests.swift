//
//  ResultsViewModelTests.swift
//  senseye-ios-sdkTests
//
//  Created by Frank Oftring on 4/22/22.
//

import XCTest
import Combine
@testable import senseye_ios_sdk
@testable import Amplify
@testable import AWSS3StoragePlugin
@testable import AWSCognitoAuthPlugin

@available(iOS 15.0, *)
class ResultsViewModelTests: XCTestCase {
    
    var model: ResultsViewModel!
    var mockFileUploadService: MockFileUploadAndPredictionService!
    var cancellables = Set<AnyCancellable>()
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        mockFileUploadService = MockFileUploadAndPredictionService()
        model = ResultsViewModel(fileUploadService: mockFileUploadService)
    }
    
    override func tearDownWithError() throws {
        model = nil
        mockFileUploadService = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Default State
    
    func testIsLoadingBeginsFalse() {
        XCTAssertFalse(model.isLoading)
    }
    
    func testErrorIsNil(){
        XCTAssertNil(model.error)
    }
    
    // MARK: - startPredictions
    
    func testWhenStartPreditionsIsLoadingEqualsTrue() {
        // Given
        model.isLoading = false
        
        // When
        model.startPredictions()
        
        // Then
        XCTAssertTrue(model.isLoading)
    }
    
    // MARK: - getPredictionResponse
    
    func testUpdatePredictionStatusWhenGetPredictionResponseIsCalled() {
        // Given
        model.predictionStatus = "(Default Status)"
        
        // When
        model.getPredictionResponse()
        
        // Then
        XCTAssertEqual(model.predictionStatus, "Starting predictions...")
    }
    
    func testGetPredictionResponseCallsStartPredictionForCurrentSessionUploadsWasCalled() {
        model.getPredictionResponse()
        XCTAssertTrue(self.mockFileUploadService.startPredictionForCurrentSessionUploadsWasCalled)
    }
    
    func testGetPredictionResponseSuccess() {
        let expectation = expectation(description: #function)
        let response = mockFileUploadService.decodeResponse()!
        mockFileUploadService.result = .success(response.id)
        
        model.$predictionStatus
            .dropFirst(2) // Drop 2. First Publisher is on initilization. Second publisher is waiting for prediction response
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        model.getPredictionResponse()
        
        wait(for: [expectation], timeout: 5)
        XCTAssertEqual(self.model.predictionStatus, "Prediction API request sent...")
        }
    
    func testGetPredictionResponseFailure() {
        let expectation = expectation(description: #function)
        mockFileUploadService.result = .failure(MockFileUploadAndPredictionServiceError.startPredictionForCurrentSessionUploads)
        
        model.$error
            .dropFirst() // Drop intialization publisher
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        model.getPredictionResponse()
        
        wait(for: [expectation], timeout: 5)
        XCTAssertNotNil(model.error)
    }
    
    // MARK: - startPeriodicPredictions
    
    func testStartPeriodicPredictionsCallSstartPeriodicUpdatesOnPredictionIdWasCalled() {
        model.startPeriodicPredictions()
        XCTAssertTrue(self.mockFileUploadService.startPeriodicUpdatesOnPredictionIdWasCalled)
    }
    
    func testStartPeriodicPredictionsSuccess() {
        let expectation = expectation(description: #function)
        let response = mockFileUploadService.decodeResponse()!
        mockFileUploadService.result = .success(response.status)

        model.$predictionStatus
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        model.startPeriodicPredictions()
        
        wait(for: [expectation], timeout: 1)
        let jobStatusAndResultResponse = response.status
        XCTAssertEqual(self.model.predictionStatus, "Returned a result for prediction... \(jobStatusAndResultResponse)")
    }
    
    func testStartPeriodicPredictionsFailure() {
        let expectation = expectation(description: #function)
        mockFileUploadService.result = .failure(MockFileUploadAndPredictionServiceError.startPeriodicUpdatesOnPredictionId)
        
        model.$error
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        model.getPredictionResponse()
        
        wait(for: [expectation], timeout: 2)
        let errorType = (self.model.error as? MockFileUploadAndPredictionServiceError) == .startPeriodicUpdatesOnPredictionId
        XCTAssertNotNil(self.model.error)
        XCTAssertTrue(errorType)
    }
}
