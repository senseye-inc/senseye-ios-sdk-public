//
//  SenseyeTabView.swift
//
//  Created by Frank Oftring on 5/24/22.
//

import SwiftUI

enum Tab {
    case imageView
    case plrView
    case confirmationView
    case resultsView
}

@available(iOS 14.0, *)
class TabController: ObservableObject {
    @Published var activeTab: Tab = .imageView
    @Published var currentTaskTitle: String = "No tasks completed yet"
    @Published var nextTab: Tab? = nil

    func open(_ tab: Tab) {
        activeTab = tab
    }

    func updateTitle(with title: String) {
        self.currentTaskTitle = title
    }
}

@available(iOS 15.0, *)
struct SenseyeTabView: View {
    @StateObject var tabController = TabController()
    @State var disbleSwipingOnTabView: Bool = true

    var body: some View {
        TabView(selection: $tabController.activeTab) {
            RotatingImageView()
                .tag(Tab.imageView)
                .gesture(disbleSwipingOnTabView ? DragGesture() : nil)

            PLRView()
                .tag(Tab.plrView)
                .gesture(disbleSwipingOnTabView ? DragGesture() : nil)

            UserConfirmationView(taskCompleted: tabController.currentTaskTitle)
                .tag(Tab.confirmationView)
                .gesture(disbleSwipingOnTabView ? DragGesture() : nil)

            // Creating a new instance for now. Will need to fix this implementation in the future and decide how to inject fileUploadService into ResultsView.
            ResultsView()
                .tag(Tab.resultsView)
                .gesture(disbleSwipingOnTabView ? DragGesture() : nil)
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .environmentObject(tabController)
        .edgesIgnoringSafeArea(.all)
        .statusBar(hidden: true)
    }
}
