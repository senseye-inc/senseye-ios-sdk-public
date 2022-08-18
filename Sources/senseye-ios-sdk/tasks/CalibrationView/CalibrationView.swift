//
//  SwiftUIView.swift
//  
//
//  Created by Frank Oftring on 6/14/22.
//

import SwiftUI

@available(iOS 15.0, *)
struct CalibrationView: View {

    @StateObject var viewModel: CalibrationViewModel
    @EnvironmentObject var tabController: TabController
    @EnvironmentObject var cameraService: CameraService
    
    init(fileUploadAndPredictionService: FileUploadAndPredictionService) {
        _viewModel = StateObject(wrappedValue: CalibrationViewModel(fileUploadService: fileUploadAndPredictionService))
    }

    var body: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)
            GeometryReader { _ in
                Circle()
                    .fill(.white)
                    .frame(width: 50, height: 50)
                    .offset(x: viewModel.xCoordinate, y: viewModel.yCoordinate)
            }
            .padding(10)
            .onReceive(cameraService.$startedCameraRecording) { hasStartedRecording in
                if (!viewModel.hasStartedTask && hasStartedRecording) {
                    viewModel.startCalibration {
                        cameraService.stopRecording()
                        viewModel.shouldShowConfirmationView.toggle()
                    }
                }
            }
        }
        .onAppear {
            cameraService.startRecordingForTask(taskId: "calibration")
        }
        .onDisappear {
            print("onDisappear triggered")
            viewModel.reset()
        }
        .fullScreenCover(isPresented: $viewModel.shouldShowConfirmationView) {
            UserConfirmationView(taskCompleted: "Calibration", yesAction: {
                cameraService.uploadLatestFile()
                viewModel.shouldShowConfirmationView.toggle()
                viewModel.addTaskInfoToJson()
                tabController.proceedToNextTab()
            }, noAction: {
                cameraService.clearLatestFileRecording()
                tabController.refreshSameTab()
            })
        }
    }
}
