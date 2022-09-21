//
//  PLRView.swift
//
//  Created by Frank Oftring on 5/23/22.
//

import SwiftUI
@available(iOS 15.0, *)
struct PLRView: View {
    
    @StateObject var viewModel: PLRViewModel
    @EnvironmentObject var tabController: TabController
    @EnvironmentObject var cameraService: CameraService
    
    init(fileUploadService: FileUploadAndPredictionService) {
        _viewModel = StateObject(wrappedValue: PLRViewModel(fileUploadService: fileUploadService))
    }
    
    var body: some View {
        ZStack {
            viewModel.backgroundColor
            
            Image(systemName: "xmark")
                .resizable()
                .foregroundColor(viewModel.xMarkColor)
                .scaledToFit()
                .frame(width: 30, height: 25.5)
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            cameraService.startRecordingForTask(taskId: "PLR")
            DispatchQueue.main.async {
                viewModel.showPLR()
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


