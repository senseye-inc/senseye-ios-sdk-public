//
//  CalibrationViewModel.swift
//  
//
//  Created by Frank Oftring on 6/14/22.
//

import SwiftUI

@available(iOS 14.0, *)
class CalibrationViewModel: ObservableObject, TaskViewModelProtocol {
    var pathIndex: Int = 0
    var hasStartedTask = false
    var taskID: String = ""
    private var taskTiming: Double {
        get {
            if (fileUploadService.isDebugModeEnabled) {
                return fileUploadService.debugModeTaskTiming
            } else {
                return 2.5
            }
        }
    }
    
    @Published var xCoordinate: CGFloat
    @Published var yCoordinate: CGFloat
    @Published var shouldShowConfirmationView: Bool = false
    @Published var isFinished: Bool = false
    
    let fileUploadService: FileUploadAndPredictionServiceProtocol
    let calibrationPath: [(CGFloat, CGFloat)] = [(80,325), (200, 675), (320,740), (80,75), (80,575), (200, 425), (320, 575), (80,740), (320, 325), (200, 175), (320, 75)]
    private var timestampsOfStimuli: [Int64] = []
    
    init(fileUploadService: FileUploadAndPredictionServiceProtocol) {
        self.fileUploadService = fileUploadService
        self.xCoordinate = calibrationPath[0].0
        self.yCoordinate = calibrationPath[0].1
    }
    
    private var calibrationTimer: Timer? = nil

    func startCalibration() {
        if calibrationTimer == nil {
            Log.info("CalibrationViewModel creating timer")
            addTimestampOfStimuliDisplay()
            hasStartedTask = true
            calibrationTimer = Timer.scheduledTimer(withTimeInterval: taskTiming, repeats: true) { [weak self] timer in
                guard let self = self else { return }
                self.pathIndex += 1
                if self.pathIndex < self.calibrationPath.count {
                    self.xCoordinate = self.calibrationPath[self.pathIndex].0
                    self.yCoordinate = self.calibrationPath[self.pathIndex].1
                    self.addTimestampOfStimuliDisplay()
                } else {
                    self.shouldShowConfirmationView.toggle()
                    self.isFinished = true
                    self.stopCalibration()
                }
            }
        }
    }
    
    private func stopCalibration() {
        if (calibrationTimer != nil) {
            calibrationTimer?.invalidate()
            Log.info("Calibration Timer Cancelled")
            calibrationTimer = nil
        }
    }
    
    private func addTimestampOfStimuliDisplay() {
        let timestamp = Date().currentTimeMillis()
        timestampsOfStimuli.append(timestamp)
        Log.info("Adding calibration event timestamp \(pathIndex) --- \(timestamp)")
    }

    func reset() {
        pathIndex = 0
        xCoordinate = calibrationPath[pathIndex].0
        yCoordinate = calibrationPath[pathIndex].1
        hasStartedTask = false
        calibrationTimer = nil
        isFinished = false
        timestampsOfStimuli.removeAll()
    }
    
    func addTaskInfoToJson() {
        var eventXLOC: [CGFloat] = []
        var eventYLOC: [CGFloat] = []
        for (xCoordinate, yCoordinate) in calibrationPath {
            eventXLOC.append(xCoordinate)
            eventYLOC.append(yCoordinate)
        }
        let taskInfo = SenseyeTask(taskID: taskID, frameTimestamps: fileUploadService.getLatestFrameTimestampArray(), timestamps: timestampsOfStimuli, eventXLOC: eventXLOC, eventYLOC: eventYLOC, videoPath: fileUploadService.getVideoPath())
        fileUploadService.addTaskRelatedInfo(for: taskInfo)
    }
}
 
