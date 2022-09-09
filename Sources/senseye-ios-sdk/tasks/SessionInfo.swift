//
//  File.swift
//  
//
//  Created by Frank Oftring on 7/27/22.
//

import Foundation
import UIKit
// MARK: - SessionInfo
struct SessionInfo: Codable {
    let versionCode, age, eyeColor, versionName, gender, folderName, username, timezone, isDebugModeEnabled: String?
    let phoneSettings: PhoneSettings?
    let phoneDetails: PhoneDetails?
    var tasks: [SenseyeTask]
    var predictionJobID: String?
}

enum TaskBlockCategory: String, Codable {
    case positive, neutral, negative, negativeArousal, facialExpression
}

enum TaskBlockSubcategory: String, Codable {
    case nature, mess, accident, negative, neutral, positive, kids, people, delay, animals, texture, broken, bodilyHarm, object, inconvenience, war, plants, buildings, frustrating, desctruction
}

// MARK: - PhoneSetting
struct PhoneSettings: Codable {
    let idlenessTimerDisabled: Bool
    let brightness, freeSpace: Int?
    let networkType: String?
    let downloadSpeed, uploadSpeed: Int?
}

// MARK: - PhoneDetails
struct PhoneDetails: Codable {
    let os, osVersion, brand, deviceType: String?
}

// MARK: - SenseyeTask
struct SenseyeTask: Codable {
    let taskID: String
    let timestamps: [Int64]?
    let eventXLOC, eventYLOC: [CGFloat]?
    let eventImageID: [String]?
    let eventBackgroundColor: [String]?
    let frameTimestamps: [Int64]?
    let blockNumber: Int?
    let category: TaskBlockCategory?
    let subcategory: TaskBlockSubcategory?

    enum CodingKeys: String, CodingKey {
        case taskID = "taskId"
        case timestamps
        case eventXLOC = "event_x_loc"
        case eventYLOC = "event_y_loc"
        case eventImageID = "event_image_id"
        case eventBackgroundColor = "event_background_color"
        case frameTimestamps
        case blockNumber = "blockNumber"
        case category = "category"
        case subcategory = "subcategory"
    }

    init(taskID: String, frameTimestamps: [Int64], timestamps: [Int64]? = nil, eventXLOC: [CGFloat]? = nil, eventYLOC: [CGFloat]? = nil, eventImageID: [String]? = nil, eventBackgroundColor: [String]? = nil, blockNumber: Int? = nil, category: TaskBlockCategory? = nil, subcategory: TaskBlockSubcategory? = nil) {
        self.taskID = taskID
        self.timestamps = timestamps
        self.eventXLOC = eventXLOC
        self.eventYLOC = eventYLOC
        self.eventImageID = eventImageID
        self.eventBackgroundColor = eventBackgroundColor
        self.frameTimestamps = frameTimestamps
        self.blockNumber = blockNumber
        self.category = category
        self.subcategory = subcategory
    }
}
