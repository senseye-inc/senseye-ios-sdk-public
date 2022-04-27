//
//  File.swift
//  
//
//  Created by Frank Oftring on 4/26/22.
//

import Foundation

// MARK: - Prediction
struct Prediction: Codable {
    let id, status: String
    let result: PredictionJobStatusResultCodable
    let timestamp: String
}

// MARK: - Result
struct PredictionJobStatusResultCodable: Codable {
    let version: String
    let prediction: PredictionClass
}

// MARK: - PredictionClass
struct PredictionClass: Codable {
    let fatigue, intoxication, threshold: Double
    let state: Int
    let processing_time: Double
}
