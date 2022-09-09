//
//  SenseyeTabView.swift
//
//  Created by Frank Oftring on 5/24/22.
//

import SwiftUI

@available(iOS 15.0, *)
struct SenseyeTabView: View {

    @EnvironmentObject var cameraService: CameraService
    @EnvironmentObject var fileUploadService: FileUploadAndPredictionService
    @EnvironmentObject var authenticationService: AuthenticationService
    var imageService: ImageService = ImageService()
    @StateObject var tabController: TabController = TabController()

    var body: some View {
        TabView(selection: $tabController.activeTabType) {
            LoginView(authenticationService: authenticationService)
                .tag(TabType.loginView)
                .gesture(DragGesture())

            SurveyView(authenticationService: authenticationService, fileUploadAndPredictionService: fileUploadService)
                .tag(TabType.surveyView)
                .gesture(DragGesture())

            CalibrationView(fileUploadAndPredictionService: fileUploadService)
                .tag(TabType.calibrationView)
                .gesture(DragGesture())

            RotatingImageView(fileUploadService: fileUploadService, imageService: imageService)
                .tag(TabType.imageView)
                .gesture(DragGesture())

            PLRView(fileUploadService: fileUploadService)
                .tag(TabType.plrView)
                .gesture(DragGesture())

            ResultsView(fileUploadService: fileUploadService)
                .tag(TabType.resultsView)
                .gesture(DragGesture())

            CameraView()
                .tag(TabType.cameraView)
                .gesture(DragGesture())
        }
        .onAppear {
            fileUploadService.setTaskCount(to: tabController.numberOfTasks())
        }
        .onChange(of: tabController.areAllTabsComplete, perform: { _ in
            cameraService.stopCaptureSession()
        })
        .tabViewStyle(.page(indexDisplayMode: .never))
        .edgesIgnoringSafeArea(.all)
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .statusBar(hidden: true)
        .environmentObject(tabController)
        .environmentObject(cameraService)
    }
}
