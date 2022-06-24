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
}

@available(iOS 14.0, *)
@MainActor
class TabController: ObservableObject {

    @Published var activeTab: Tab = .loginView
    var nextTab: Tab = .imageView

    func open(_ tab: Tab) {
        activeTab = tab
    }
}

@available(iOS 15.0, *)
struct SenseyeTabView: View {

    @EnvironmentObject var cameraService: CameraService
    @EnvironmentObject var fileUploadService: FileUploadAndPredictionService
    @EnvironmentObject var authenticationService: AuthenticationService

    @StateObject var tabController: TabController = TabController()

    var body: some View {

        NavigationView {
            TabView(selection: $tabController.activeTab) {
                LoginView(authenticationService: authenticationService)
                    .tag(Tab.loginView)
                    .gesture(DragGesture())

                SurveyView()
                    .tag(Tab.surveyView)
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
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
            .statusBar(hidden: true)
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .environmentObject(tabController)
            .environmentObject(cameraService)
            .edgesIgnoringSafeArea(.all)
        }
    }
}
