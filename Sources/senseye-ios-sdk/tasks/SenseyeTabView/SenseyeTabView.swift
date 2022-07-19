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
    @StateObject var tabController: TabController = TabController()

    var body: some View {
        TabView(selection: $tabController.activeTab) {
            LoginView(authenticationService: authenticationService)
                .tag(Tab.loginView)
                .gesture(DragGesture())

            SurveyView(authenticationService: authenticationService, fileUploadAndPredictionService: fileUploadService)
                .tag(Tab.surveyView)
                .gesture(DragGesture())

            CalibrationView(fileUploadAndPredictionService: fileUploadService)
                .tag(Tab.calibrationView)
                .gesture(DragGesture())

            RotatingImageView(fileUploadService: fileUploadService)
                .tag(Tab.imageView)
                .gesture(DragGesture())

            PLRView()
                .tag(Tab.plrView)
                .gesture(DragGesture())

            ResultsView(fileUploadService: fileUploadService)
                .tag(Tab.resultsView)
                .gesture(DragGesture())

            CameraView()
                .tag(Tab.cameraView)
                .gesture(DragGesture())
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
