//
//  File.swift
//  
//
//  Created by Frank Oftring on 4/25/22.
//

import Foundation
import Combine
@testable import senseye_ios_sdk
@available(iOS 13.0, *)
class MockFileUploadAndPredictionService {
    
    var result: Result<String, Error> = .failure(MockFileUploadAndPredictionServiceError.notInitialized)
    
    var startPredictionForCurrentSessionUploadsWasCalled: Bool = false
    var startPeriodicUpdatesOnPredictionIdWasCalled: Bool = false
    
    let predictionResponse = MockPredictionResponse(
        id: "3fa85f64-5717-4562-b3fc-2c963f66afa6",
        status: "completed",
        result: MockPredictionResult(
            version: "0.0.1",
            prediction: MockPredictionDetail(
                fatigue: 0.4567890123456789,
                intoxication: 0.4567890123456789,
                threshold: 0.5,
                state: 0,
                processing_time: 56.7890123456789)),
        timestamp: "2022-04-26T14:55:14.621Z")
    
}

enum MockFileUploadAndPredictionServiceError: Error {
    case startPredictionForCurrentSessionUploads
    case startPeriodicUpdatesOnPredictionId
    case notInitialized
}

@available(iOS 13.0, *)
extension MockFileUploadAndPredictionService: FileUploadAndPredictionServiceProtocol {
    func uploadData(fileUrl: URL) {

    }

    func createSessionInputJsonFile(surveyInput: [String : String]) {
        
    }

    var uploadProgress: Double {
        0.0
    }


    var uploadProgressPublished: Published<Double> {
        Published(initialValue: 0.0)
    }

    var uploadProgressPublisher: Published<Double>.Publisher {
        var uploadProgressPublished = Published(initialValue: 0.0)
        return uploadProgressPublished.projectedValue
    }

    var numberOfUploads: Double {
        0.0
    }

    
    func startPredictionForCurrentSessionUploads(completed: @escaping (Result<String, Error>) -> Void) {
        startPredictionForCurrentSessionUploadsWasCalled = true
        completed(result)
    }
    
    func startPeriodicUpdatesOnPredictionId(completed: @escaping (Result<String, Error>) -> Void) {
        startPeriodicUpdatesOnPredictionIdWasCalled = true
        completed(result)
    }
    
    func downloadIndividualImageAssets(imageS3Key: String, successfullCompletion: @escaping () -> Void) {
    }
    
    func uploadSessionJsonFile() {
    }
    
    
    func addTaskRelatedInfoToSessionJson(taskId: String, taskTimestamps: [Int64]) {
    }
}

