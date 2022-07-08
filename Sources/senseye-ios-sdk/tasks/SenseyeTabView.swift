//
//  SenseyeTabView.swift
//
//  Created by Frank Oftring on 5/24/22.
//

import SwiftUI

enum Tab {
    case imageView
    case plrView
    case resultsView
    case cameraView
    case loginView
    case surveyView
    case calibrationView
}

extension Tab {
    func retrieveTaskInfoForTab() -> (String, String) {
        switch self {
        case .imageView:
            return ("PTSD Image Set", "8 different images will come across the screen. \n Note: Some of the images may be disturbing.")
        case .plrView:
            return ("PLR", "Stare at the cross for the duration of the task.")
        case .calibrationView:
            return ("Calibration", "When a ball appears look at it as quickly as possible, and remain staring at it until it disappears.")
        default:
            return ("","")
        }
        
    }
}

@available(iOS 14.0, *)
@MainActor
class TabController: ObservableObject {

    @Published var activeTab: Tab = .loginView
    private var nextTab: Tab = .calibrationView
    private var currentTabIndex = 0

    private var taskTabOrdering: [Tab] = [.loginView, .surveyView, .cameraView, .calibrationView, .cameraView, .imageView, .cameraView, .plrView, .resultsView]
    
    var areAllTabsComplete: Bool {
        currentTabIndex >= taskTabOrdering.count - 1
    }
    
    func refreshSameTab() {
        open(.cameraView)
        currentTabIndex-=1
    }
    
    func proceedToNextTab() {
        currentTabIndex+=1
        nextTab = taskTabOrdering[currentTabIndex]
        openNextTab()
    }
    
    func openNextTab() {
        DispatchQueue.main.async {
            self.activeTab = self.nextTab
        }
    }

    func openPreviousTab() {
        currentTabIndex-=1
        nextTab = taskTabOrdering[currentTabIndex]
        openNextTab()
    }

    
    func taskInfoForNextTab() -> (String, String) {
        let nextTabIndex = currentTabIndex+1
        return taskTabOrdering[nextTabIndex].retrieveTaskInfoForTab()
    }
    
    private func open(_ tab: Tab) {
        DispatchQueue.main.async {
            self.activeTab = tab
        }
    }
}

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

            SurveyView(authenticationService: authenticationService)
                .tag(Tab.surveyView)
                .gesture(DragGesture())

            CalibrationView()
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
        .tabViewStyle(.page(indexDisplayMode: .never))
        .edgesIgnoringSafeArea(.all)
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .statusBar(hidden: true)
        .environmentObject(tabController)
        .environmentObject(cameraService)
    }
}
