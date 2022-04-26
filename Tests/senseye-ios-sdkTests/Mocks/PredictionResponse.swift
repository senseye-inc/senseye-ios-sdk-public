//
//  File.swift
//  
//
//  Created by Frank Oftring on 4/26/22.
//

import Foundation

// MARK: - Prediction
struct Prediction: Codable {
    let id, status: String?
    let preditionResult: PredictionResult?
    let timestamp: String?
}

// MARK: - Result
struct PredictionResult: Codable {
    let version: String?
    let prediction: PredictionClass?
}

// MARK: - PredictionClass
struct PredictionClass: Codable {
    let fatigue, intoxication, threshold: Double?
    let state: Int?
    let processingTime: Double?

    enum CodingKeys: String, CodingKey {
        case fatigue, intoxication, threshold, state
        case processingTime = "processing_time"
    }
}
