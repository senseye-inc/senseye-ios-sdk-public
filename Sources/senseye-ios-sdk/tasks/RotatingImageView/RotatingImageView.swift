//
//  ImageView.swift
//
//  Created by Frank Oftring on 5/19/22.
//

import SwiftUI

@available(iOS 15.0, *)
struct RotatingImageView: View {
    
    @StateObject var viewModel: RotatingImageViewModel
    
    init(fileUploadService: FileUploadAndPredictionService, imageService: ImageService) {
        _viewModel = StateObject(wrappedValue: RotatingImageViewModel(fileUploadService: fileUploadService, imageService: imageService))
    }
    
    @EnvironmentObject var tabController: TabController
    @EnvironmentObject var cameraService: CameraService
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                SingleImageView(isLoading: $viewModel.isLoading, image: viewModel.currentImage)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .onAppear {
                        viewModel.checkForImages()
                        DispatchQueue.main.async {
                            cameraService.startRecordingForTask(taskId: "aiv")
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
            }
        }
        .fullScreenCover(isPresented: $viewModel.shouldShowConfirmationView) {
            UserConfirmationView(taskCompleted: viewModel.taskCompleted, yesAction: {
                cameraService.uploadLatestFile()
                viewModel.shouldShowConfirmationView.toggle()
                viewModel.addTaskInfoToJson()
                tabController.proceedToNextTab()
            }, noAction: {
                cameraService.clearLatestFileRecording()
                viewModel.removeLastImageSet()
                tabController.refreshSameTab()
            })
        }
    }
}
