//
//  PLRViewModel.swift
//
//  Created by Frank Oftring on 5/25/22.
//

import Foundation
import SwiftUI

@available(iOS 14.0, *)
class PLRViewModel: ObservableObject, TaskViewModelProtocol {

    @Published var backgroundColor: Color = .black
    @Published var xMarkColor: Color = .white
    @Published var shouldShowConfirmationView: Bool = false
    @Published var hasStartedTask = false
    @Published var isFinished: Bool = false
    private var taskTiming: Double {
        get {
            if (fileUploadService.isDebugModeEnabled) {
                return fileUploadService.debugModeTaskTiming
            } else {
                return 5.0
            }
        }
    }

    var currentInterval: Int = 0
    private var timestampsOfBackgroundSwap: [Int64] = []
    private var eventBackgroundColor: [String] = []
    private let fileUploadService: FileUploadAndPredictionServiceProtocol
    
    init(fileUploadService: FileUploadAndPredictionServiceProtocol) {
        self.fileUploadService = fileUploadService
    }
    
    private var plrTimer: Timer? = nil

    func showPLR() {
        if plrTimer == nil {
            Log.info("PLRViewModel creating timer")
            hasStartedTask = true
            plrTimer = Timer.scheduledTimer(withTimeInterval: taskTiming, repeats: true) { [weak self] timer in
                guard let self = self else { return }
                self.currentInterval += 1
                if self.currentInterval <= 1 {
                    self.toggleColors()
                    self.timestampsOfBackgroundSwap.append(Date().self.currentTimeMillis())
                } else {
                    self.shouldShowConfirmationView.toggle()
                    self.isFinished = true
                    self.stopPLR()
                }
            }
        }
    }
    
    private func stopPLR() {
        if (plrTimer != nil) {
            plrTimer?.invalidate()
            Log.info("PLRView Timer Cancelled")
            plrTimer = nil
        }
    }

    private func toggleColors() {
        backgroundColor = (backgroundColor == .white ? .black : .white)
        xMarkColor = (xMarkColor == .black ? .white : .black)
        eventBackgroundColor.append(xMarkColor.toHex() ?? "")
    }

    func reset() {
        currentInterval = 0
        hasStartedTask = false
        backgroundColor = .black
        xMarkColor = .white
        plrTimer = nil
        isFinished = false
        eventBackgroundColor.removeAll()
        timestampsOfBackgroundSwap.removeAll()
    }
    
    func addTaskInfoToJson() {
        let taskInfo = SenseyeTask(taskID: "plr", frameTimestamps: fileUploadService.getLatestFrameTimestampArray(), timestamps: timestampsOfBackgroundSwap, eventBackgroundColor: eventBackgroundColor, videoPath: fileUploadService.getVideoPath())
        fileUploadService.addTaskRelatedInfo(for: taskInfo)
    }
}
