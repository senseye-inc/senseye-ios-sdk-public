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

struct CameraView: View {
    
    @EnvironmentObject var cameraService: CameraService
    @EnvironmentObject var tabController: TabController
    @StateObject var vm: CameraViewModel
    
    init(fileUploadService: FileUploadAndPredictionService) {
        _vm = StateObject(wrappedValue: CameraViewModel(fileUploadService: fileUploadService))
    }
    
    var body: some View {
        GeometryReader { _ in
            ZStack {
                FrameView(image: $cameraService.frame)
                VStack {
                    if (vm.shouldShowFacialComplianceLabel) {
                        FacialComplianceLabelView(currentComplianceInfo: $cameraService.currentComplianceInfo)
                    } else {
                        Spacer()
                    }
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
            .onChange(of: vm.shouldProceedToNextTab) { shouldProceedToNextTab in
                if shouldProceedToNextTab {
                    tabController.proceedToNextTab()
                }
            }
            .edgesIgnoringSafeArea(.all)
            .alert(Strings.needCameraAccess, isPresented: $cameraService.shouldShowCameraPermissionsDeniedAlert) {
                Button(Strings.gotoSettingsButtonTitle) {
                    cameraService.goToSettings()
                }
            } message: {
                Text(Strings.cameraPermissionsDescripton)
            }
        }
    }
}
