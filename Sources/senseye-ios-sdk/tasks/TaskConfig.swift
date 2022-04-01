//
//  File.swift
//  
//
//  Created by Deepak Kumar on 11/23/21.
//

import Foundation
import UIKit

public enum PathType: String {
    case calibration
    case smoothPursuit
    case plr
}

struct TaskOption {
    let path: [(Int,Int)]
    let type: PathType
    let title: String
    let taskId: String
    let shouldShowX: Bool
    
    init(path: [(Int,Int)], type: PathType, title: String, taskId: String, shouldShowX: Bool) {
        self.path = path
        self.type = type
        self.title = title
        self.taskId = taskId
        self.shouldShowX = shouldShowX
    }
}

class TaskConfig {
    
    var calibrationPath = TaskOption(path: [(300, 75), (75,600), (200, 500), (75, 200), (300, 600), (75, 600), (150, 200), (200, 500), (250, 200), (250, 600)], type: .calibration, title: "Calibration", taskId: "ios_calibration", shouldShowX: false)
    
    var smoothPursuitPath = TaskOption(path: [(330, 320)], type: .smoothPursuit, title: "Smooth Pursuit", taskId: "ios_smooth_pursuit", shouldShowX: true)
    let smoothPursuitRepeatCount: Float = 9.0
    let smoothPursuitDuration: Double = 1.0
    let smoothPursuitAnimationSpeed: Float = 0.2
    let smoothPursuitCircleRadius: CGFloat = 150
    
    var plrPath = TaskOption(path: [], type: .plr, title: "PLR", taskId: "ios_plr", shouldShowX: true)
    let plrBackgroundColorAndTiming: [Int: UIColor] = [0: .white, 5: .black, 10: .white, 15: .black]
    let plrTaskLengthInSec = 20
    
    private var availablePathOptions: [TaskOption]
    
    init() {
        availablePathOptions = [plrPath, calibrationPath, smoothPursuitPath]
    }
    
    func pathOptionsForTaskIds(ids: [String]) -> [TaskOption] {
        var optionsToReturn: [TaskOption] = []
        for option in availablePathOptions {
            if (ids.contains(option.type.rawValue)) {
                optionsToReturn.append(option)
            }
        }
        return optionsToReturn
    }
    
    func xMarkColorForBackground(backgroundColor: UIColor) -> UIColor {
        if (backgroundColor == .black) {
            return UIColor.white
        } else {
            return UIColor.black
        }
    }
    
}