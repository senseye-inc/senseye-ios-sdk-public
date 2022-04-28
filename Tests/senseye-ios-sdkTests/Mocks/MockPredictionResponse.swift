//
//  File.swift
//  
//
//  Created by Frank Oftring on 4/26/22.
//

import Foundation


// MARK: - Prediction
struct MockPredictionResponse: Codable {
    let id, status: String
    let result: MockPredictionResult
    let timestamp: String
}

// MARK: - Result
struct MockPredictionResult: Codable {
    let version: String
    let prediction: MockPredictionDetail
}

// MARK: - PredictionClass
struct MockPredictionDetail: Codable {
    let fatigue, intoxication, threshold: Double
    let state: Int
    let processing_time: Double
}
