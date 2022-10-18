//
//  FaceDotProbeView.swift
//  
//
//  Created by Frank Oftring on 9/22/22.
//

import Foundation
import SwiftUI


@available(iOS 15.0, *)
struct AttentionBiasFaceView: View {
    
    @StateObject var viewModel: AttentionBiasFaceViewModel
    @EnvironmentObject var tabController: TabController
    @EnvironmentObject var cameraService: CameraService
    
    init(fileUploadAndPredictionService: FileUploadAndPredictionService) {
        _viewModel = StateObject(wrappedValue: AttentionBiasFaceViewModel(fileUploadService: fileUploadAndPredictionService))
    }
    
    var body: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)
            CurrentFaceBlockView(currentTopImage: viewModel.currentTopImage, currentBottomImage: viewModel.currentBottomImage, isShowingImages: viewModel.isShowingImages, dotLocation: viewModel.dotLocation, isShowingXMark: viewModel.isShowingXMark)
        }
        .onAppear {
            cameraService.startRecordingForTask(taskId: "AttentionBiasFace")
            DispatchQueue.main.async {
                viewModel.start()
            }
        }
        .onChange(of: viewModel.isFinished) { isFinished in
            if isFinished {
                cameraService.stopRecording()
            }
        }
        .onDisappear {
            Log.info("onDisappear triggered")
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

struct SingleFaceView: View {
    var image: String?
    var isShowingImages: Bool
    let showDot: Bool
    var body: some View {
        ZStack{
            if showDot {
                dotView
            }
            Text(image ?? "empty")
                .font(.system(size: 150))
                .opacity(isShowingImages ? 1.0 : 0.0)
        }
    }
}


struct CurrentFaceBlockView: View {
    
    let currentTopImage: String?
    let currentBottomImage: String?
    let isShowingImages: Bool
    let dotLocation: DotLocation?
    let isShowingXMark: Bool
    
    var body: some View {
        VStack {
            SingleFaceView(image: currentTopImage, isShowingImages: isShowingImages, showDot: dotLocation == .top ? true : false)
            Image(systemName: "xmark")
                .resizable()
                .foregroundColor(.white)
                .scaledToFit()
                .frame(width: 50)
                .opacity(isShowingXMark ? 1.0 : 0.0)
            SingleFaceView(image: currentBottomImage, isShowingImages: isShowingImages, showDot: dotLocation == .bottom ? true : false)
        }
    }
}

extension SingleFaceView {
    var dotView: some View {
        Circle()
            .foregroundColor(.white)
            .frame(height: 40)
            .opacity((isShowingImages) ? 0.0: 1.0)
    }
}
