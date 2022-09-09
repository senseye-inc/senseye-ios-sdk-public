//
//  CalibrationViewModel.swift
//  
//
//  Created by Frank Oftring on 6/14/22.
//

import SwiftUI

@available(iOS 13.0, *)
@MainActor
class CalibrationViewModel: ObservableObject, TaskViewModelProtocol {
    var pathIndex: Int = 0
    var hasStartedTask = false
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
    
    let fileUploadService: FileUploadAndPredictionServiceProtocol
    let calibrationPath: [(CGFloat, CGFloat)] = [(80,325), (200, 675), (320,740), (80,75), (80,575), (200, 425), (320, 575), (80,740), (320, 325), (200, 175), (320, 75)]
    private var timestampsOfStimuli: [Int64] = []
    
    init(fileUploadService: FileUploadAndPredictionServiceProtocol) {
        self.fileUploadService = fileUploadService
        self.xCoordinate = calibrationPath[0].0
        self.yCoordinate = calibrationPath[0].1
    }

    func startCalibration(didFinishCompletion: @escaping () -> Void) {
        hasStartedTask = true
        Timer.scheduledTimer(withTimeInterval: taskTiming, repeats: true) { [self] timer in
            pathIndex += 1
            if pathIndex < calibrationPath.count {
                xCoordinate = calibrationPath[pathIndex].0
                yCoordinate = calibrationPath[pathIndex].1
                addTimestampOfStimuliDisplay()
            } else {
                timer.invalidate()
                Log.info("Calibration Timer Cancelled")
                didFinishCompletion()
            }
        }
        addTimestampOfStimuliDisplay()
    }
    
    private func addTimestampOfStimuliDisplay() {
        let timestamp = Date().currentTimeMillis()
        timestampsOfStimuli.append(timestamp)
        Log.info("Adding calibration event timestamp \(pathIndex) --- \(timestamp)")
    }

    func reset() {
        self.pathIndex = 0
        self.xCoordinate = self.calibrationPath[self.pathIndex].0
        self.yCoordinate = self.calibrationPath[self.pathIndex].1
        self.hasStartedTask = false
        timestampsOfStimuli.removeAll()
    }
    
    func addTaskInfoToJson() {
        var eventXLOC: [CGFloat] = []
        var eventYLOC: [CGFloat] = []
        for (xCoordinate, yCoordinate) in calibrationPath {
            eventXLOC.append(xCoordinate)
            eventYLOC.append(yCoordinate)
        }
        let taskInfo = SenseyeTask(taskID: "calibration", frameTimestamps: fileUploadService.getLatestFrameTimestampArray(), timestamps: timestampsOfStimuli, eventXLOC: eventXLOC, eventYLOC: eventYLOC)
        fileUploadService.addTaskRelatedInfo(for: taskInfo)
    }
}
 
