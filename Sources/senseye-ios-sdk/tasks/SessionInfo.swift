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
    let versionCode, age, eyeColor, versionName, gender, folderName, username, timezone: String?
    let isDebugModeEnabled: Bool?
    let isCensorModeEnabled: Bool?
    let phoneSettings: PhoneSettings?
    let phoneDetails: PhoneDetails?
    var tasks: [SenseyeTask]
    var predictionJobID: String?
    var asDictionary : [String:Any]? {
        let mirror = Mirror(reflecting: self)
        let dict = Dictionary(uniqueKeysWithValues: mirror.children.lazy.map({ (label:String?, value:Any) -> (String, Any)? in
            guard let label = label else { return nil }
            return (label, value)
        }).compactMap { $0 })
        return dict
    }
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
    let os, osVersion, brand, deviceType: String?, cameraType: String?
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
    let plethysmograph: [UInt8]?
    let pulseRate: [UInt8]?
    let spo2: [UInt8]?
    let videoPath: String?

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
        case plethysmograph
        case pulseRate = "pulse_rate"
        case spo2
        case videoPath

    }

    init(
        taskID: String,
        frameTimestamps: [Int64],
        timestamps: [Int64]? = nil,
        eventXLOC: [CGFloat]? = nil,
        eventYLOC: [CGFloat]? = nil,
        eventImageID: [String]? = nil,
        eventBackgroundColor: [String]? = nil,
        blockNumber: Int? = nil,
        category: TaskBlockCategory? = nil,
        subcategory: TaskBlockSubcategory? = nil,
        plethysmograph: [UInt8]? = nil,
        pulseRate: [UInt8]? = nil,
        spo2: [UInt8]? = nil,
        videoPath: String? = nil
    ) {
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
        self.plethysmograph = plethysmograph
        self.spo2 = spo2
        self.pulseRate = pulseRate
        self.videoPath = videoPath
    }
}

enum AppStorageKeys: String {
    case cameraType
    case username

    func callAsFunction() -> String {
        return self.rawValue
    }
}

