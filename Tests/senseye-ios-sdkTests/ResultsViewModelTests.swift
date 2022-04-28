//
//  ResultsViewModelTests.swift
//  senseye-ios-sdkTests
//
//  Created by Frank Oftring on 4/22/22.
//

import XCTest
import Combine
@testable import senseye_ios_sdk

// Naming Structure: test_UnitOfWork_StateUnderTest_ExpectedBehavior

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
    
    func test_isLoading_shouldBeFalse() {
        XCTAssertFalse(model.isLoading)
    }
    
    func test_error_shouldBeNil(){
        XCTAssertNil(model.error)
    }
    
    // MARK: - startPredictions
    func test_startPredictions_isLoadingShouldBeTrue() {
        // Given
        model.isLoading = false
        
        // When
        model.startPredictions()
        
        // Then
        XCTAssertTrue(model.isLoading)
    }
    
    // MARK: - getPredictionResponse
    
    func test_getPredictionResponse_updatesPredictionStatus() {
        // Given
        model.predictionStatus = "(Default Status)"
        
        // When
        model.getPredictionResponse()
        
        // Then
        XCTAssertEqual(model.predictionStatus, "Starting predictions...")
    }
    
    func test_getPredictionResponse_startPredictionForCurrentSessionUploadsShouldBeTrue() {
        model.getPredictionResponse()
        XCTAssertTrue(self.mockFileUploadService.startPredictionForCurrentSessionUploadsWasCalled)
    }
    
    func test_getPredictionResponseSuccess_updatesPredictionStatus() {
        let expectation = expectation(description: #function)
        let response = mockFileUploadService.predictionResponse
        mockFileUploadService.result = .success(response.id)
        
        model.$predictionStatus
            .dropFirst(2) // Drop 2. First Publisher is on initilization. Second publisher is waiting for prediction response
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        model.getPredictionResponse()
        
        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(self.model.predictionStatus, "Prediction API request sent...")
        }
    
    func test_getPredictionResponseFailure_errorIsNotNil() {
        let expectation = expectation(description: #function)
        mockFileUploadService.result = .failure(MockFileUploadAndPredictionServiceError.startPredictionForCurrentSessionUploads)
        
        model.$error
            .dropFirst() // Drop intialization publisher
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        model.getPredictionResponse()
        
        wait(for: [expectation], timeout: 1)
        let errorType = (self.model.error as? MockFileUploadAndPredictionServiceError) == .startPredictionForCurrentSessionUploads
        XCTAssertNotNil(self.model.error)
        XCTAssertTrue(errorType)
    }
    
    // MARK: - startPeriodicPredictions
    
    func test_startPeriodicPredictions_startPeriodicUpdatesOnPredictionIdShouldBeTrue() {
        model.startPeriodicPredictions()
        XCTAssertTrue(self.mockFileUploadService.startPeriodicUpdatesOnPredictionIdWasCalled)
    }
    
    func test_startPeriodicPredictionsSuccess_updatesPredictionStatus() {
        let expectation = expectation(description: #function)
        let response = mockFileUploadService.predictionResponse
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
    
    func test_startPeriodicPredictionsFailure_errorIsNotNil() {
        let expectation = expectation(description: #function)
        mockFileUploadService.result = .failure(MockFileUploadAndPredictionServiceError.startPeriodicUpdatesOnPredictionId)
        
        model.$error
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        model.getPredictionResponse()
        
        wait(for: [expectation], timeout: 1)
        let errorType = (self.model.error as? MockFileUploadAndPredictionServiceError) == .startPeriodicUpdatesOnPredictionId
        XCTAssertNotNil(self.model.error)
        XCTAssertTrue(errorType)
    }
}
