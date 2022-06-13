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
}

@available(iOS 14.0, *)
@MainActor
class TabController: ObservableObject {
    @Published var activeTab: Tab = .cameraView

    var currentTaskTitle: String = "N/A"
    var nextTab: Tab = .imageView

    func open(_ tab: Tab) {
        activeTab = tab
    }
}

@available(iOS 15.0, *)
struct SenseyeTabView: View {

    @StateObject var tabController = TabController()
    @StateObject var cameraService: CameraService

    let fileUploadService: FileUploadAndPredictionService

    init(fileUploadService: FileUploadAndPredictionService) {
        _cameraService = StateObject(wrappedValue: CameraService(fileUploadService: fileUploadService))
        self.fileUploadService = fileUploadService
    }

    var body: some View {
        TabView(selection: $tabController.activeTab) {
            RotatingImageView()
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
        .onAppear(perform: {
            cameraService.start()
        })
        .navigationTitle("")
        .navigationBarHidden(true)
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .environmentObject(tabController)
        .environmentObject(cameraService)
        .edgesIgnoringSafeArea(.all)
        .statusBar(hidden: true)
    }
}
