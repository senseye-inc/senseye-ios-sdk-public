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
    let versionCode, age, eyeColor, versionName: String
    let gender: String
    let tasks: [SenseyeTask]
}

// MARK: - Task
struct SenseyeTask: Codable {
    let taskID: String
    let timestamps: [Int64]?
    let eventXLOC, eventYLOC: [CGFloat]?
    let eventImageID: [String]?
    let eventBackgroundColor: [String]?

    enum CodingKeys: String, CodingKey {
        case taskID = "taskId"
        case timestamps
        case eventXLOC = "event_x_loc"
        case eventYLOC = "event_y_loc"
        case eventImageID = "event_image_id"
        case eventBackgroundColor = "event_background_color"
    }

    init(taskID: String, timestamps: [Int64]? = nil, eventXLOC: [CGFloat]? = nil, eventYLOC: [CGFloat]? = nil, eventImageID: [String]? = nil, eventBackgroundColor: [String]? = nil) {
        self.taskID = taskID
        self.timestamps = timestamps
        self.eventXLOC = eventXLOC
        self.eventYLOC = eventYLOC
        self.eventImageID = eventImageID
        self.eventBackgroundColor = eventBackgroundColor
    }
}
