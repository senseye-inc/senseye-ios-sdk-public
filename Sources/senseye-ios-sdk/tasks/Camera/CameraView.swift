//
//  CameraView.swift
//  
//
//  Created by Frank Oftring on 6/1/22.
//

import SwiftUI
import AVFoundation
import Amplify

@available(iOS 15.0, *)
struct CameraView: View {
    
    @EnvironmentObject var cameraService: CameraService
    @EnvironmentObject var tabController: TabController
    @State private var showingOverlay = false
    
    var body: some View {
        GeometryReader { _ in
            ZStack {
                FrameView(image: $cameraService.frame)
                VStack {
                    FacialComplianceLabelView(currentComplianceIcon: $cameraService.currentComplianceInfo.statusIcon, currentComplianceLabel: $cameraService.currentComplianceInfo.statusMessage, currentComplianceColor: $cameraService.currentComplianceInfo.statusBackgroundColor)
                    Button { } label: {
                        CameraButtonOverlayView()
                            .onTapGesture(count: 2) {
                                tabController.proceedToNextTab()
                            }
                    }
                    .disabled(!cameraService.shouldSetupCaptureSession || showingOverlay)
                }
                
                if showingOverlay {
                    let taskInfo = tabController.taskInfoForNextTab()
                    SenseyeInfoOverlay(title: taskInfo.0, description: taskInfo.1, showingOverlay: $showingOverlay)
                }
            }
            .onAppear {
                cameraService.start()
                showingOverlay.toggle()
                Log.info("displayed cameraview")
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
