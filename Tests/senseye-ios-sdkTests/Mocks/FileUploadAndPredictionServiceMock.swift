//
//  File.swift
//  
//
//  Created by Frank Oftring on 4/25/22.
//

import Foundation
@testable import senseye_ios_sdk

class FileUploadAndPredictionServiceMock {
    
    var result: Result<String, Error> = .failure(MockFileUploadAndPredictionServiceError.notInitialized)
    
    var startPredictionForCurrentSessionUploadsWasCalled: Bool = false
    var startPeriodicUpdatesOnPredictionIdWasCalled: Bool = false
    
    let jsonResponse: [String: Any] = [
        "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
        "status": "completed",
        "result": [
            "version": "0.0.1",
            "prediction": [
                "fatigue": 0.4567890123456789,
                "intoxication": 0.4567890123456789,
                "threshold": 0.5,
                "state": 0,
                "processing_time": 56.7890123456789
            ]
        ],
        "timestamp": "2022-04-26T14:55:14.621Z"
    ]
    
    func decodeResponse() -> Prediction? {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonResponse, options: .prettyPrinted) else {
            print("Error decoding JSON")
            return nil
        }
        
        do {
            let predictionResult = try JSONDecoder().decode(Prediction.self, from: jsonData)
            return predictionResult
        } catch {
            print("Error building predictionResposne")
            print(error.localizedDescription)
            return nil
        }
    }
}

enum MockFileUploadAndPredictionServiceError: Error {
    case startPredictionForCurrentSessionUploads
    case startPeriodicUpdatesOnPredictionId
    case notInitialized
}

extension FileUploadAndPredictionServiceMock: FileUploadAndPredictionServiceProtocol {
    
    func startPredictionForCurrentSessionUploads(completed: @escaping (Result<String, Error>) -> Void) {
        startPredictionForCurrentSessionUploadsWasCalled = true
        completed(result)
    }
    
    func startPeriodicUpdatesOnPredictionId(completed: @escaping (Result<String, Error>) -> Void) {
        startPeriodicUpdatesOnPredictionIdWasCalled = true
        completed(result)
    }
}
