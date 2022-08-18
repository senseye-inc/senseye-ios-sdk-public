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

    var currentInterval: Int = 0
    private var timestampsOfBackgroundSwap: [Int64] = []
    private var eventBackgroundColor: [String] = []
    private let fileUploadService: FileUploadAndPredictionServiceProtocol
    
    init(fileUploadService: FileUploadAndPredictionServiceProtocol) {
        self.fileUploadService = fileUploadService
    }
    

    func showPLR(didFinishCompletion: @escaping () -> Void) {
        hasStartedTask = true
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [self] timer in
            currentInterval += 1
            if currentInterval <= 10 {
                DispatchQueue.main.async {
                    self.toggleColors()
                }
                timestampsOfBackgroundSwap.append(Date().currentTimeMillis())
            } else {
                timer.invalidate()
                Log.info("PLRView Timer Cancelled")
                didFinishCompletion()
            }
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
        timestampsOfBackgroundSwap.removeAll()
    }
    
    func addTaskInfoToJson() {
        let taskInfo = SenseyeTask(taskID: "plr", frameTimestamps: fileUploadService.getLatestFrameTimestampArray(), timestamps: timestampsOfBackgroundSwap, eventBackgroundColor: eventBackgroundColor)
        fileUploadService.addTaskRelatedInfo(for: taskInfo)
    }
}
