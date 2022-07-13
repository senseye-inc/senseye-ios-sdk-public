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
                        }
                }
                .disabled(!cameraService.shouldSetupCaptureSession)
            }
        }
        .onAppear {
            cameraService.start()
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
        .sheet(isPresented: $cameraService.shouldDisplayPretaskTutorial, onDismiss: {
            dismissAllSheets()
        }, content: {
            let taskInfo = tabController.taskInfoForNextTab()
            PreTaskInstructionView(title: taskInfo.0, description: taskInfo.1)
        })

    }
    
    func dismissAllSheets() {
        Log.info("dismissed the sheet")
        cameraService.shouldDisplayPretaskTutorial = false
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
