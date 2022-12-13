//
//  File.swift
//  
//
//  Created by Deepak Kumar on 9/30/22.
//

import Foundation
import SwiftUI

@available(iOS 14.0, *)
class HRCalibrationViewModel: ObservableObject, TaskViewModelProtocol {
    
    @Published var shouldShowConfirmationView: Bool = false
    var backgroundColor: Color = .gray
    
    private let fileUploadService: FileUploadAndPredictionServiceProtocol
    
    private var startingTimestamp: Int64 = Int64(0)
    private var endingTimestamp: Int64 = Int64(0)
    
    init(fileUploadService: FileUploadAndPredictionServiceProtocol) {
        self.fileUploadService = fileUploadService
    }
    
    private var taskTiming: Double {
        get {
            if (fileUploadService.isDebugModeEnabled) {
                return 5
            } else {
                return 180
            }
        }
    }
    
    func startHRCalibration() {
        startingTimestamp = Date().currentTimeMillis()
        DispatchQueue.main.asyncAfter(deadline: .now() + taskTiming) {
            self.shouldShowConfirmationView.toggle()
            self.endingTimestamp = Date().currentTimeMillis()
        }
    }
    
    func addTaskInfoToJson() {
        let startAndEndTimestampsOfHR = [startingTimestamp, endingTimestamp]
        let taskInfo = SenseyeTask(taskID: "hr_calibration", frameTimestamps: [], timestamps: startAndEndTimestampsOfHR)
        fileUploadService.addTaskRelatedInfo(for: taskInfo)
    }
    
}
