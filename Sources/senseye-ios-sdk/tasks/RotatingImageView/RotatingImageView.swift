//
//  ImageView.swift
//
//  Created by Frank Oftring on 5/19/22.
//

import SwiftUI

@available(iOS 15.0, *)
struct RotatingImageView: View {

    @StateObject var viewModel: RotatingImageViewModel
    @State var hasStartedTask = false
    
    init(fileUploadService: FileUploadAndPredictionService) {
        _viewModel = StateObject(wrappedValue: RotatingImageViewModel(fileUploadService: fileUploadService))
    }
    
    @EnvironmentObject var tabController: TabController
    @EnvironmentObject var cameraService: CameraService

    var body: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)

            GeometryReader { geometry in
                SingleImageView(imageName: viewModel.currentImageName!)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .onReceive(self.cameraService.$startedCameraRecording) { isStarted in
                        if (!hasStartedTask && self.cameraService.startedCameraRecording) {
                            self.hasStartedTask = true
                            viewModel.downloadPtsdImageSetsIfRequired {
                                DispatchQueue.main.async {
                                    viewModel.showImages {
                                        cameraService.stopRecording()
                                        viewModel.shouldShowConfirmationView.toggle()
                                    }
                                }
                            }
                        }
                    }
                    .onAppear {
                        cameraService.startRecordingForTask(taskId: "aiv_\(viewModel.numberOfImageSetsShown)")
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
