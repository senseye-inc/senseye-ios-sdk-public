//
//  ImageView.swift
//
//  Created by Frank Oftring on 5/19/22.
//

import SwiftUI

struct RotatingImageView: View {
    
    @EnvironmentObject var tabController: TabController
    @EnvironmentObject var cameraService: CameraService
    @StateObject var viewModel: RotatingImageViewModel
    
    init(fileUploadService: FileUploadAndPredictionService, imageService: ImageService) {
        _viewModel = StateObject(wrappedValue: RotatingImageViewModel(fileUploadService: fileUploadService, imageService: imageService))
    }
    
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                SingleImageView(isLoading: $viewModel.isLoading, image: viewModel.currentImage)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .onAppear {
                        let tabCategoryAndSubCategory = tabController.cateogryAndSubcategoryForCurrentTab()
                        viewModel.tabInfo = RotatingImageViewTaskInfo(taskBlockNumber: tabController.activeTabBlockNumber, taskCategory: tabCategoryAndSubCategory.0, taskSubcategory: tabCategoryAndSubCategory.1)
                        cameraService.startRecordingForTask(taskId: "aiv")
                        DispatchQueue.main.async {
                            viewModel.checkForImages()
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
            UserConfirmationView(yesAction: {
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
