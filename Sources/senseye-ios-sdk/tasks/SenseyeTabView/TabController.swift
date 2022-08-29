//
//  TabController.swift
//  
//
//  Created by Frank Oftring on 7/8/22.
//

import Foundation

enum TabType {
    case imageView
    case plrView
    case resultsView
    case cameraView
    case loginView
    case surveyView
    case calibrationView
}

struct TabItem: Hashable {
    let taskId: String
    let tabType: TabType
    let blockNumber: Int?
    
    init(taskId: String, tabType: TabType, blockNumber: Int? = nil) {
        self.taskId = taskId
        self.tabType = tabType
        self.blockNumber = blockNumber
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(taskId)
        hasher.combine(tabType)
    }
}

extension TabType {
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


    private var taskTabOrdering: [TabItem] = [TabItem(taskId: "login_view", tabType: .loginView),
                                              TabItem(taskId: "survey_view", tabType: .surveyView),
                                              TabItem(taskId: "camera_view_calibration", tabType: .cameraView, blockNumber: 0),
                                              TabItem(taskId: "calibration_view_1", tabType: .calibrationView, blockNumber: 1),
                                              TabItem(taskId: "camera_view_plr", tabType: .cameraView, blockNumber: 2),
                                              TabItem(taskId: "plr_view", tabType: .plrView, blockNumber: 2),
                                              TabItem(taskId: "camera_view_affective_image_set_1", tabType: .cameraView, blockNumber: 2),
                                              TabItem(taskId: "affective_image_set_1", tabType: .imageView, blockNumber: 2),
                                              TabItem(taskId: "camera_view_affective_image_set_2", tabType: .cameraView, blockNumber: 3),
                                              TabItem(taskId: "affective_image_set_2", tabType: .imageView, blockNumber: 3),
                                              TabItem(taskId: "camera_view_calibration", tabType: .cameraView, blockNumber: 4),
                                              TabItem(taskId: "calibration_view_2", tabType: .calibrationView, blockNumber: 4),
                                              TabItem(taskId: "results_view", tabType: .resultsView)]
    
    @Published var activeTabType: TabType = .loginView
    var activeTabBlockNumber: Int?
    private var nextTab: TabItem?
    private var currentTabIndex = 0

    var areAllTabsComplete: Bool {
        currentTabIndex >= taskTabOrdering.count - 1
    }

    func refreshSameTab() {
        currentTabIndex-=1
        open(taskTabOrdering[currentTabIndex])
    }

    func proceedToNextTab() {
        currentTabIndex+=1
        nextTab = taskTabOrdering[currentTabIndex]
        openNextTab()
    }

    func openNextTab() {
        guard let updatedTab = self.nextTab else {
            return
        }
        DispatchQueue.main.async {
            self.activeTabType = updatedTab.tabType
            self.activeTabBlockNumber = updatedTab.blockNumber
        }
    }

    func proceedToPreviousTab() {
        currentTabIndex-=1
        nextTab = taskTabOrdering[currentTabIndex]
        openNextTab()
    }


    func taskInfoForNextTab() -> (String, String) {
        let nextTabIndex = currentTabIndex+1
        return taskTabOrdering[nextTabIndex].tabType.retrieveTaskInfoForTab()
    }

    private func open(_ tab: TabItem) {
        DispatchQueue.main.async {
            self.activeTabType = tab.tabType
            self.activeTabBlockNumber = tab.blockNumber
        }
    }
}
