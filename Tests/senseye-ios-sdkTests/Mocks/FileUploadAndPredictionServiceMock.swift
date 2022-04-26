//
//  File.swift
//  
//
//  Created by Frank Oftring on 4/25/22.
//

import Foundation
@testable import senseye_ios_sdk

class FileUploadAndPredictionServiceMock {
    
    var shouldReturnError: Bool = false
    var startPredictionWasCalled: Bool = false
    var startPeriodicUpdatesWasCalled: Bool = false
    
    func reset() {
        shouldReturnError = false
        startPredictionWasCalled = false
        startPeriodicUpdatesWasCalled = false
    }
    
    func decodeResponse() -> Prediction? {
        let fileURL = URL(fileURLWithPath: "/Users/frank/Desktop/senseye-ios-sdk/Tests/senseye-ios-sdkTests/Mocks/prediction-success-response.json")
        
        guard let data = try? Data(contentsOf: fileURL) else {
            print("Error decoding JSON")
            return nil
        }
        
        do {
            let predictionResult = try JSONDecoder().decode(Prediction.self, from: data)
            return predictionResult
        } catch {
            print("Error building predictionResposne")
            print(error.localizedDescription)
            return nil
        }
        
        
    }
    
    enum MockFileUploadAndPredictionServiceError: Error {
        case startPredictionForCurrentSessionUploads
        case startPeriodicUpdatesOnPredictionId
    }
    
}

extension FileUploadAndPredictionServiceMock: FileUploadAndPredictionServiceProtocol {
    
    func startPredictionForCurrentSessionUploads(completed: @escaping (Result<String, Error>) -> Void) {
        
        let predictionResult = self.decodeResponse()
        let predictionStatus = predictionResult?.status ?? "Error decoding prediction status"
        
        startPredictionWasCalled = true
        
        if shouldReturnError {
            completed(.failure(MockFileUploadAndPredictionServiceError.startPredictionForCurrentSessionUploads))
        } else {
            completed(.success(predictionStatus))
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
