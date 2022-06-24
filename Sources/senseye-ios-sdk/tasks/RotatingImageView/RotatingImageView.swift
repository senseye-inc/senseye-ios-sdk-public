//
//  ImageView.swift
//
//  Created by Frank Oftring on 5/19/22.
//

import SwiftUI

@available(iOS 15.0, *)
struct RotatingImageView: View {

    @StateObject var viewModel: RotatingImageViewModel
    
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
                HStack(spacing: 0) {
                    SingleImageView(imageName: viewModel.currentImageName)
                }
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .leading)
                .onAppear {
                    viewModel.downloadPtsdImageSetsIfRequired {
                        DispatchQueue.main.async {
                            cameraService.startRecordingForTask(taskId: "PTSD_\(viewModel.numberOfImageSetsShown)")
                            viewModel.showImages {
                                cameraService.stopRecording()
                                viewModel.shouldShowConfirmationView.toggle()
                            }
                        }
                    }
                    
                }
            }
        }
        .fullScreenCover(isPresented: $viewModel.shouldShowConfirmationView) {
            // Dismiss Action
        } content: {
            UserConfirmationView(taskCompleted: viewModel.taskCompleted, yesAction: {
                viewModel.shouldShowConfirmationView.toggle()
                if viewModel.finishedAllTasks {
                    cameraService.stopCaptureSession()
                    Log.info("Finsished all tasks")
                    tabController.open(.resultsView)
                } else {
                    tabController.nextTab = .plrView
                    tabController.open(.cameraView)
                }
            }, noAction: {
                viewModel.removeLastImageSet()
                tabController.nextTab = .imageView
            })
        }
    }
}
