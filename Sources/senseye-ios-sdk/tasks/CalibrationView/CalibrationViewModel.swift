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
    var taskCompleted: String = "Calibration"
    @Published var xCoordinate: CGFloat = 0
    @Published var yCoordinate: CGFloat = 0
    @Published var shouldShowConfirmationView: Bool = false
    
    let fileUploadService: FileUploadAndPredictionServiceProtocol
    var numberOfCalibrationShown: Int = 1
    let calibrationPath: [(CGFloat, CGFloat)] = [(300, 75), (75,600), (200, 500), (75, 200), (300, 600), (75, 600), (150, 200), (200, 500), (250, 200), (250, 600)]
    private var timestampsOfStimuli: [Int64] = []
    
    init(fileUploadService: FileUploadAndPredictionServiceProtocol) {
        self.fileUploadService = fileUploadService
    }

    func startCalibration(didFinishCompletion: @escaping () -> Void) {
        numberOfCalibrationShown += 1
        Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [self] timer in
            if pathIndex < calibrationPath.count {
                xCoordinate = calibrationPath[pathIndex].0
                yCoordinate = calibrationPath[pathIndex].1
                pathIndex += 1
                timestampsOfStimuli.append(Date().currentTimeMillis())
            } else {
                timer.invalidate()
                Log.info("Calibration Timer Cancelled")
                reset()
                didFinishCompletion()
            }
        }
    }

    func reset() {
        pathIndex = 0
    }
    
    func addTaskInfoToJson() {
        let eventXLOC: [Int] = []
        let yventXLOC: [Int] = []
        let taskInfo = SenseyeTask(taskID: "calibration", eventXLOC: <#T##[Int]?#>)
        fileUploadService.addTaskRelatedInfoToSessionJson(taskId: "calibration", taskTimestamps: timestampsOfStimuli)
    }
}
