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
    var startPredictionForCurrentSessionUploadsWasCalled: Bool = false
    var startPeriodicUpdatesOnPredictionIdWasCalled: Bool = false
    
    convenience init() {
        self.init(false)
    }
    
    init(_ shouldReturnError: Bool) {
        self.shouldReturnError = shouldReturnError
    }
    
    func reset() {
        shouldReturnError = false
        startPredictionForCurrentSessionUploadsWasCalled = false
        startPeriodicUpdatesOnPredictionIdWasCalled = false
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

enum MockFileUploadAndPredictionServiceError: Error {
    case startPredictionForCurrentSessionUploads
    case startPeriodicUpdatesOnPredictionId
}

extension FileUploadAndPredictionServiceMock: FileUploadAndPredictionServiceProtocol {
    
    func startPredictionForCurrentSessionUploads(completed: @escaping (Result<String, Error>) -> Void) {
        
        startPredictionForCurrentSessionUploadsWasCalled = true
        
        if shouldReturnError {
            completed(.failure(MockFileUploadAndPredictionServiceError.startPredictionForCurrentSessionUploads))
        } else {
            let predictionResult = self.decodeResponse()
            let predictionStatus = predictionResult?.status ?? "Error decoding prediction status"
            completed(.success(predictionStatus))
        }
    }
    
    func startPeriodicUpdatesOnPredictionId(completed: @escaping (Result<String, Error>) -> Void) {
        
        startPeriodicUpdatesOnPredictionIdWasCalled = true
        
        if shouldReturnError {
            completed(.failure(MockFileUploadAndPredictionServiceError.startPeriodicUpdatesOnPredictionId))
        } else {
            completed(.success("Success String from \(#function)"))
        }
    }
}
