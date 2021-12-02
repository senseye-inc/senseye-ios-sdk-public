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
}

struct TaskOption {
    let path: [(Int,Int)]
    let type: PathType
    let title: String
    
    init(path: [(Int,Int)], type: PathType, title: String) {
        self.path = path
        self.type = type
        self.title = title
    }
}

class TaskConfig {
    
    var calibrationPath = TaskOption(path: [(300, 75), (75,600), (200, 500), (75, 200), (300, 600), (75, 600), (150, 200), (200, 500), (250, 200), (250, 600)], type: .calibration, title: "Calibration")
    
    var smoothPursuitPath = TaskOption(path: [(330, 320)], type: .smoothPursuit, title: "Smooth Pursuit")
    let smoothPursuitRepeatCount: Float = 3.0
    let smoothPursuitDuration: Double = 1.0
    let smoothPursuitAnimationSpeed: Float = 0.2
    let smoothPursuitCircleRadius: CGFloat = 150
    
    private var availablePathOptions: [TaskOption]
    
    init() {
        availablePathOptions = [calibrationPath, smoothPursuitPath]
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
    
}
