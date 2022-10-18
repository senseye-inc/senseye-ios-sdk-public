//
//  CameraView.swift
//  
//
//  Created by Frank Oftring on 6/1/22.
//

import SwiftUI
import AVFoundation
import Amplify
import Combine

@available(iOS 15.0, *)
struct CameraView: View {
    
    @EnvironmentObject var cameraService: CameraService
    @EnvironmentObject var tabController: TabController
    @StateObject var vm: CameraViewModel = CameraViewModel()
    
    var body: some View {
        GeometryReader { _ in
            ZStack {
                FrameView(image: $cameraService.frame)
                VStack {
                    Button { } label: {
                        CameraButtonOverlayView(callToActionText: $vm.callToActionText)
                            .onTapGesture(count: 2) {
                                vm.shouldProceedToNextTab.toggle()
                            }
                    }
                    .disabled(!cameraService.shouldSetupCaptureSession || vm.isShowingOverlay)
                }
                
                if vm.isShowingOverlay {
                    let taskInfo = tabController.taskInfoForNextTab()
                    SenseyeInfoOverlay(title: taskInfo.0, description: taskInfo.1, showingOverlay: $vm.isShowingOverlay)
                }
            }
            .onAppear {
                cameraService.start()
                vm.onAppear()
                Log.info("displayed cameraview")
            }
            .onDisappear {
                vm.onDisappear()
            }
            .onChange(of: vm.shouldProceedToNextTab) { shouldProceedToNextTab in
                if shouldProceedToNextTab {
                    tabController.proceedToNextTab()
                }
            }
            .edgesIgnoringSafeArea(.all)
            .alert("Need Camera Access", isPresented: $cameraService.shouldShowCameraPermissionsDeniedAlert) {
                Button("Go to settings") {
                    cameraService.goToSettings()
                }
            } message: {
                Text("Change camera permissions in your settings.")
            }
        }
    }
}
