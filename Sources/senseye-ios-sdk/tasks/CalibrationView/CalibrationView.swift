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
                    .frame(width: 35)
                    .position(x: viewModel.xCoordinate, y: viewModel.yCoordinate)
            }
        }
        .onAppear {
            let taskID = tabController.taskIDForCurrentTab()
            viewModel.taskID = taskID
            cameraService.startRecordingForTask(taskId: taskID)
            DispatchQueue.main.async {
                viewModel.startCalibration()
            }
        }
        .onChange(of: viewModel.isFinished) { isFinished in
            if isFinished {
                cameraService.stopRecording()
            }
        }
        .onDisappear {
            viewModel.reset()
        }
        .fullScreenCover(isPresented: $viewModel.shouldShowConfirmationView) {
            UserConfirmationView(yesAction: {
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
