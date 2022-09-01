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
    let taskTitle: String
    let taskDescription: String
    let blockNumber: Int?
    let category: TaskBlockCategory?
    let subcategory: TaskBlockSubcategory?
    
    
    init(taskId: String, tabType: TabType, taskTitle: String = "", taskDescription: String = "", blockNumber: Int? = nil, category: TaskBlockCategory? = nil, subcategory: TaskBlockSubcategory? = nil) {
        self.taskId = taskId
        self.tabType = tabType
        self.taskTitle = taskTitle
        self.taskDescription = taskDescription
        self.blockNumber = blockNumber
        self.category = category
        self.subcategory = subcategory
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(taskId)
        hasher.combine(tabType)
    }
}

@available(iOS 14.0, *)
@MainActor
class TabController: ObservableObject {


    private var taskTabOrdering: [TabItem] = [
        TabItem(taskId: "login_view", tabType: .loginView),
        TabItem(taskId: "survey_view", tabType: .surveyView),
        TabItem(taskId: "camera_view_calibration", tabType: .cameraView),
        TabItem(taskId: "calibration_view_1",
                tabType: .calibrationView,
                taskTitle: "Calibration",
                taskDescription: "When a ball appears look at it as quickly as possible, and remain staring at it until it disappears."),
        TabItem(taskId: "camera_view_plr", tabType: .cameraView),
        TabItem(taskId: "plr_view",
                tabType: .plrView,
                taskTitle: "PLR",
                taskDescription: "Stare at the cross for the duration of the task."),
        TabItem(taskId: "camera_view_affective_image_set_1", tabType: .cameraView, blockNumber: 2),
        TabItem(taskId: "affective_image_set_1",
                tabType: .imageView,
                taskTitle: "PTSD Image Set - Block 1",
                taskDescription: "8 different images will come across the screen. \n Note: Some of the images may be disturbing.",
                blockNumber: 1,
                category: .positive,
                subcategory: .animals),
        TabItem(taskId: "camera_view_calibration", tabType: .cameraView),
        TabItem(taskId: "calibration_view_2",
                tabType: .calibrationView,
                taskTitle: "Calibration",
                taskDescription: "When a ball appears look at it as quickly as possible, and remain staring at it until it disappears."),
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
        let tabItem = taskTabOrdering[nextTabIndex]
        return (tabItem.taskTitle, tabItem.taskDescription)
    }
    
    func titleForCurrentTab() -> String {
        let currentTab = taskTabOrdering[currentTabIndex]
        return currentTab.taskTitle
    }
    
    func cateogryAndSubcategoryForCurrentTab() -> (TaskBlockCategory?, TaskBlockSubcategory?) {
        let currentTab = taskTabOrdering[currentTabIndex]
        return (currentTab.category, currentTab.subcategory)
    }

    private func open(_ tab: TabItem) {
        DispatchQueue.main.async {
            self.activeTabType = tab.tabType
            self.activeTabBlockNumber = tab.blockNumber
        }
    }
}
