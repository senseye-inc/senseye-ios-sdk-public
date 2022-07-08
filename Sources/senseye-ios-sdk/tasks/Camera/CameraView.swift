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

    var body: some View {
        ZStack {
            CameraPreview(cameraService: cameraService)
            VStack {
                Button { } label: {
                    CameraButtonOverlayView()
                        .onTapGesture(count: 2) {
                            tabController.proceedToNextTab()
                            //tabController.open(tabController.nextTab)
                        }
                }
                .disabled(!cameraService.shouldSetupCaptureSession)
            }
        }
        .onAppear {
            cameraService.start()
            DispatchQueue.main.async {
                cameraService.shouldDisplayPretaskTutorial = true
            }
            Log.info("displayed cameraview")
        }
        .sheet(isPresented: $cameraService.shouldDisplayPretaskTutorial) {
            let taskInfo = tabController.taskInfoForNextTab()
            PreTaskInstructionView(isPresented: $cameraService.shouldDisplayPretaskTutorial, title: taskInfo.0, description: taskInfo.1)
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

@available(iOS 13.0, *)
struct CameraPreview: UIViewRepresentable {

    let cameraService: CameraService

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        cameraService.setupVideoPreviewLayer(for: view)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) { }
}
