//
//  CalibrationViewModel.swift
//  
//
//  Created by Frank Oftring on 6/14/22.
//

import SwiftUI

@available(iOS 13.0, *)
@MainActor
class CalibrationViewModel: ObservableObject {
    var pathIndex: Int = 0
    var taskCompleted: String = "Calibration"
    @Published var xCoordinate: CGFloat = 0
    @Published var yCoordinate: CGFloat = 0
    @Published var shouldShowConfirmationView: Bool = false

    let calibrationPath: [(CGFloat, CGFloat)] = [(300, 75), (75,600), (200, 500), (75, 200), (300, 600), (75, 600), (150, 200), (200, 500), (250, 200), (250, 600)]

    func startCalibration(didFinishCompletion: @escaping () -> Void) {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [self] timer in
            if pathIndex < calibrationPath.count {
                xCoordinate = calibrationPath[pathIndex].0
                yCoordinate = calibrationPath[pathIndex].1
                pathIndex += 1
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
}
