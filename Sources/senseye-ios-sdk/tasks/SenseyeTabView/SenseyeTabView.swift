//
//  SenseyeTabView.swift
//
//  Created by Frank Oftring on 5/24/22.
//

import SwiftUI

struct SenseyeTabView: View {

    @EnvironmentObject var authenticationService: AuthenticationService
    @EnvironmentObject var fileUploadService: FileUploadAndPredictionService
    @EnvironmentObject var imageService: ImageService
    @EnvironmentObject var cameraService: CameraService
    @StateObject var tabController: TabController
    
    init(taskIds: [SenseyeSDK.TaskId], shouldCollectSurveyInfo: Bool, requiresAuth: Bool) {
        _tabController = StateObject(wrappedValue: TabController(taskIds: taskIds, shouldCollectSurveyInfo: shouldCollectSurveyInfo, requiresAuth: requiresAuth))
    }

    var body: some View {
        TabView(selection: $tabController.activeTabType) {
            LoginView(authenticationService: authenticationService)
                .tag(TabType.loginView)
                .gesture(DragGesture())

            SurveyView(fileUploadAndPredictionService: fileUploadService, imageService: imageService, authenticationService: authenticationService)
                .tag(TabType.surveyView)
                .gesture(DragGesture())
            
            HRCalibrationView(fileUploadService: fileUploadService)
                .tag(TabType.hrCalibrationView)
                .gesture(DragGesture())

            CalibrationView(fileUploadAndPredictionService: fileUploadService)
                .tag(TabType.calibrationView)
                .gesture(DragGesture())

            RotatingImageView(fileUploadService: fileUploadService, imageService: imageService)
                .tag(TabType.affectiveImageView)
                .gesture(DragGesture())

            PLRView(fileUploadService: fileUploadService)
                .tag(TabType.plrView)
                .gesture(DragGesture())

            ResultsView(fileUploadService: fileUploadService)
                .tag(TabType.resultsView)
                .gesture(DragGesture())

            CameraView(fileUploadService: fileUploadService)
                .tag(TabType.cameraView)
                .disableScrolling(disabled: true)
            
            AttentionBiasFaceView(fileUploadAndPredictionService: fileUploadService, imageService: imageService)
                .tag(TabType.attentionBiasFaceView)
                .gesture(DragGesture())
        }
        .onAppear {
            fileUploadService.configureTaskSession(with: tabController.taskTabOrdering)
        }
        .onChange(of: tabController.areAllTabsComplete, perform: { _ in
            cameraService.stopCaptureSession()
        })
        .onChange(of: tabController.areInternalTestingTasksEnabled, perform: { _ in
            tabController.updateCurrentTabSet()
            Log.info("task count ---- \(fileUploadService.taskCount)")
            fileUploadService.configureTaskSession(with: tabController.taskTabOrdering)
        })
        .tabViewStyle(.page(indexDisplayMode: .never))
        .edgesIgnoringSafeArea(.all)
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .statusBar(hidden: true)
        .environmentObject(tabController)
    }
}
