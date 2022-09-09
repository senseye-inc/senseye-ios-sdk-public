//
//  PredictionRequest.swift
//  
//
//  Created by Frank Oftring on 8/29/22.
//

import Foundation

// MARK: - PredictionRequest
struct PredictionRequest: Codable {
    let workers, timeout: Int?
    let sqsDeadLetterQueue: SQSDeadLetterQueue?
    let filePathLister: FilePathLister?
    let config: [String: String]?

    enum CodingKeys: String, CodingKey {
        case workers, timeout
        case sqsDeadLetterQueue = "sqs_dead_letter_queue"
        case filePathLister = "file_path_lister"
        case config
    }
}

// MARK: - FilePathLister
struct FilePathLister: Codable {
    let s3Paths: [String]?
    let includes, excludes: [String]?
    let batchSize: Int?

    enum CodingKeys: String, CodingKey {
        case s3Paths = "s3_paths"
        case includes, excludes
        case batchSize = "batch_size"
    }
}

// MARK: - SqsDeadLetterQueue
struct SQSDeadLetterQueue: Codable {
    let arn: String?
    let maxReceiveCount: Int?

    enum CodingKeys: String, CodingKey {
        case arn
        case maxReceiveCount = "max_receive_count"
    }
}

// MARK: - PredictionResponse
struct PredictionResponse: Codable {
    let jobID, apiName, kind: String
    let workers: Int
    let sqsDeadLetterQueue: SQSDeadLetterQueue
    let config: [String: String]
    let timeout: Int
    let apiID, sqsURL, startTime: String

    enum CodingKeys: String, CodingKey {
        case jobID = "job_id"
        case apiName = "api_name"
        case kind, workers
        case sqsDeadLetterQueue = "sqs_dead_letter_queue"
        case config, timeout
        case apiID = "api_id"
        case sqsURL = "sqs_url"
        case startTime = "start_time"
    }
}
