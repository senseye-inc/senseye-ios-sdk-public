//
//  SwiftUIView.swift
//  
//
//  Created by Frank Oftring on 6/14/22.
//

import SwiftUI

@available(iOS 15.0, *)
struct CalibrationView: View {

    @StateObject var viewModel = CalibrationViewModel()
    @EnvironmentObject var tabController: TabController
    @EnvironmentObject var cameraService: CameraService

    var body: some View {
        ZStack {
            Color.black
            GeometryReader { _ in

                Circle()
                    .fill(.white)
                    .frame(width: 50, height: 50)
                    .offset(x: viewModel.xCoordinate, y: viewModel.yCoordinate)
            }
        }
        .onAppear {
            cameraService.startRecordingForTask(taskId: "calibration_\(viewModel.numberOfCalibrationShown)")
            viewModel.startCalibration {
                cameraService.stopRecording()
                viewModel.shouldShowConfirmationView.toggle()
            }
        }
        .fullScreenCover(isPresented: $viewModel.shouldShowConfirmationView) {
            UserConfirmationView(taskCompleted: "Calibration", yesAction: {
                cameraService.uploadLatestFile()
                viewModel.shouldShowConfirmationView.toggle()
                tabController.proceedToNextTab()
            }, noAction: {
                cameraService.clearLatestFileRecording()
                tabController.refreshSameTab()
            })
        }
    }
}
