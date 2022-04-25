//
//  File.swift
//  
//
//  Created by Frank Oftring on 4/25/22.
//

import Foundation
@testable import senseye_ios_sdk

class FileUploadAndPredictionServiceMock {
    
    var completion: Result<String, Error>?
    var shouldReturnError: Bool = false
    var startPredictionWasCalled: Bool = false
    var startPeriodicUpdatesWasCalled: Bool = false
    
    let mockStartPredictionForCurrentSessionUploadsResponse = "Success from \(#function)"
    let mockStartPeriodicUpdatesOnPredictionIdResponse = "Success from \(#function)"
    
    func reset() {
        shouldReturnError = false
        startPredictionWasCalled = false
        startPeriodicUpdatesWasCalled = false
    }
    
    enum MockFileUploadAndPredictionServiceError: Error {
        case startPredictionForCurrentSessionUploads
        case startPeriodicUpdatesOnPredictionId
    }
    
}

extension FileUploadAndPredictionServiceMock: FileUploadAndPredictionServiceProtocol {
    
    func startPredictionForCurrentSessionUploads(completed: @escaping (Result<String, Error>) -> Void) {
        
        startPredictionWasCalled = true
        
        if shouldReturnError {
            completed(.failure(MockFileUploadAndPredictionServiceError.startPredictionForCurrentSessionUploads))
        } else {
            completed(.success(mockStartPredictionForCurrentSessionUploadsResponse))
        }
    }
    
    func startPeriodicUpdatesOnPredictionId(completed: @escaping (Result<String, Error>) -> Void) {
        
        startPeriodicUpdatesWasCalled = true
        
        if shouldReturnError {
            completed(.failure(MockFileUploadAndPredictionServiceError.startPeriodicUpdatesOnPredictionId))
        } else {
            completed(.success(mockStartPeriodicUpdatesOnPredictionIdResponse))
        }
    }
}
