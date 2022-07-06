//
//  ResultsViewModelTests.swift
//  senseye-ios-sdkTests
//
//  Created by Frank Oftring on 4/22/22.
//

import XCTest
import Combine
@testable import senseye_ios_sdk

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
    
    func testIsLoadigShouldBeFalse() {
        XCTAssertFalse(model.isLoading)
    }
    
    func testErrorShouldBeNil(){
        XCTAssertNil(model.error)
    }
    
    // MARK: - startPredictions
    func testStartPredictionsIsLoadingShouldBeTrue() {
        // Given
        model.isLoading = false
        
        // When
        model.startPredictions()
        
        // Then
        XCTAssertTrue(model.isLoading)
    }
    
    // MARK: - getPredictionResponse
    
    func testGetPredictionResponseUpdatesPredictionStatus() {
        // Given
        model.predictionStatus = .none
        
        // When
        model.getPredictionResponse()
        
        // Then
        XCTAssertEqual(model.predictionStatus, .none)
    }
    
    func testGetPredictionResponseStartPredictionForCurrentSessionUploadsShouldBeTrue() {
        // When
        model.getPredictionResponse()
        
        // Then
        XCTAssertTrue(mockFileUploadService.startPredictionForCurrentSessionUploadsWasCalled)
    }
    
    func testGetPredictionResponseSuccessUpdatesPredictionStatus() {
        // Given
        let expectation = expectation(description: #function)
        let response = mockFileUploadService.predictionResponse
        mockFileUploadService.result = .success(response.id)
        
        // using Combine framework for testing aynchronous events
        model.$predictionStatus
            .dropFirst(2)  // Drop 2. First publisher is on initilization. Second publisher is waiting for prediction response
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        model.getPredictionResponse()
        
        // Then
        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(self.model.predictionStatus, .apiRequestSent)
        }
    
    func testGetPredictionResponseFailureErrorIsNotNil() {
        // Given
        let expectation = expectation(description: #function)
        mockFileUploadService.result = .failure(MockFileUploadAndPredictionServiceError.startPredictionForCurrentSessionUploads)
        
        // using Combine framework for testing aynchronous events
        model.$error
            .dropFirst() // Drop intialization publisher
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        model.getPredictionResponse()
        
        // Then
        wait(for: [expectation], timeout: 1)
        let errorType = (self.model.error as? MockFileUploadAndPredictionServiceError) == .startPredictionForCurrentSessionUploads
        XCTAssertNotNil(self.model.error)
        XCTAssertTrue(errorType)
    }
    
    // MARK: - startPeriodicPredictions
    
    func testStartPeriodicPredictionsStartPeriodicUpdatesOnPredictionIdShouldBeTrue() {
        // When
        model.startPeriodicPredictions()
        
        // Then
        XCTAssertTrue(self.mockFileUploadService.startPeriodicUpdatesOnPredictionIdWasCalled)
    }
    
    func testStartPeriodicPredictionsSuccessUpdatesPredictionStatus() {
        // Given
        let expectation = expectation(description: #function)
        let response = mockFileUploadService.predictionResponse
        mockFileUploadService.result = .success(response.status)

        // using Combine framework for testing aynchronous events
        model.$predictionStatus
            .dropFirst() // Drop intialization publisher
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        model.startPeriodicPredictions()
        
        // Then
        wait(for: [expectation], timeout: 1)
        let jobStatusAndResultResponse = response.status
        XCTAssertEqual(self.model.predictionStatus, .returnedPrediction(jobStatusAndResultResponse))
    }
    
    func testStartPeriodicPredictionsFailureErrorIsNotNil() {
        // Given
        let expectation = expectation(description: #function)
        mockFileUploadService.result = .failure(MockFileUploadAndPredictionServiceError.startPeriodicUpdatesOnPredictionId)
        
        model.$error
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        model.getPredictionResponse()
        
        // Then
        wait(for: [expectation], timeout: 1)
        let errorType = (self.model.error as? MockFileUploadAndPredictionServiceError) == .startPeriodicUpdatesOnPredictionId
        XCTAssertNotNil(self.model.error)
        XCTAssertTrue(errorType)
    }
}
