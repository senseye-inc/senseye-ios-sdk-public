//
//  PLRView.swift
//
//  Created by Frank Oftring on 5/23/22.
//

import SwiftUI
@available(iOS 15.0, *)
struct PLRView: View {

    @StateObject var viewModel: PLRViewModel = PLRViewModel()
    @EnvironmentObject var tabController: TabController
    @EnvironmentObject var cameraService: CameraService

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
            cameraService.startRecordingForTask(taskId: "PLR_\(viewModel.numberOfPLRShown)")
            viewModel.showPLR {
                cameraService.stopRecording()
                tabController.nextTab = .imageView
                viewModel.shouldShowConfirmationView.toggle()
            }
        }
        .fullScreenCover(isPresented: $viewModel.shouldShowConfirmationView) {
            // Dismiss Action
        } content: {
            UserConfirmationView(taskCompleted: "PLR", yesAction: {
                viewModel.shouldShowConfirmationView.toggle()
                tabController.open(.cameraView)
            }, noAction: {
                tabController.nextTab = .plrView
            })
        }
    }
}


