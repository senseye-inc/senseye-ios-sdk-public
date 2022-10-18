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
    case attentionBiasFaceView
    case hrCalibrationView
}

struct TabItem: Hashable {
    let taskId: String
    let tabType: TabType
    let taskTitle: String
    let taskDescription: String
    let blockNumber: Int?
    let category: TaskBlockCategory?
    let subcategory: TaskBlockSubcategory?
    let isTaskItem: Bool
    
    
    init(taskId: String, tabType: TabType, taskTitle: String = "", taskDescription: String = "", blockNumber: Int? = nil, category: TaskBlockCategory? = nil, subcategory: TaskBlockSubcategory? = nil, isTaskItem: Bool = false) {
        self.taskId = taskId
        self.tabType = tabType
        self.taskTitle = taskTitle
        self.taskDescription = taskDescription
        self.blockNumber = blockNumber
        self.category = category
        self.subcategory = subcategory
        self.isTaskItem = isTaskItem
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(taskId)
        hasher.combine(tabType)
    }
}

@available(iOS 14.0, *)
@MainActor
class TabController: ObservableObject {

    private var taskTabOrdering: [TabItem] = []
    
    @Published var activeTabType: TabType = .loginView
    var activeTabBlockNumber: Int?
    private var nextTab: TabItem?
    private var currentTabIndex = 0
    
    init() {
        //Initial Tabs
        taskTabOrdering += [TabItem(taskId: "login_view", tabType: .loginView),
                            TabItem(taskId: "survey_view", tabType: .surveyView)]
        //HR Calibration
        taskTabOrdering += [
            TabItem(taskId: "heart_rate_calibration",
                    tabType: .hrCalibrationView,
                    taskTitle: "Heart Rate Calibration",
                    taskDescription: "Relax and sit still for 3 minutes while we measure your baseline heart rate!",
                    isTaskItem: true)]
        
        //Starting Calibration
        taskTabOrdering += [
            TabItem(taskId: "camera_view_calibration", tabType: .cameraView),
            TabItem(
                taskId: "calibration_view_1",
                tabType: .calibrationView,
                taskTitle: "Calibration",
                taskDescription: "When a ball appears look at it as quickly as possible, and remain staring at it until it disappears.",
                isTaskItem: true)]
        
        //Image Set Blocks
        taskTabOrdering.append(contentsOf: tasksForImageSetBlock(blockNumber: 1, category: .positive, subcategory: .nature))
        taskTabOrdering.append(contentsOf: tasksForImageSetBlock(blockNumber: 2, category: .neutral, subcategory: .nature))
        taskTabOrdering.append(contentsOf: tasksForImageSetBlock(blockNumber: 3, category: .negative, subcategory: .mess))
        taskTabOrdering.append(contentsOf: tasksForImageSetBlock(blockNumber: 4, category: .negativeArousal, subcategory: .accident))
        taskTabOrdering.append(contentsOf: tasksForImageSetBlock(blockNumber: 5, category: .facialExpression, subcategory: .negative))
        taskTabOrdering.append(contentsOf: tasksForImageSetBlock(blockNumber: 6, category: .positive, subcategory: .kids))
        taskTabOrdering.append(contentsOf: tasksForImageSetBlock(blockNumber: 7, category: .neutral, subcategory: .people))
        taskTabOrdering.append(contentsOf: tasksForImageSetBlock(blockNumber: 8, category: .negative, subcategory: .delay))
        taskTabOrdering.append(contentsOf: tasksForImageSetBlock(blockNumber: 9, category: .negativeArousal, subcategory: .animals))
        taskTabOrdering.append(contentsOf: tasksForImageSetBlock(blockNumber: 10, category: .facialExpression, subcategory: .negative))
        taskTabOrdering.append(contentsOf: tasksForImageSetBlock(blockNumber: 11, category: .positive, subcategory: .animals))
        taskTabOrdering.append(contentsOf: tasksForImageSetBlock(blockNumber: 12, category: .neutral, subcategory: .texture))
        taskTabOrdering.append(contentsOf: tasksForImageSetBlock(blockNumber: 13, category: .negative, subcategory: .broken))
        taskTabOrdering.append(contentsOf: tasksForImageSetBlock(blockNumber: 14, category: .negativeArousal, subcategory: .bodilyHarm))
        taskTabOrdering.append(contentsOf: tasksForImageSetBlock(blockNumber: 15, category: .facialExpression, subcategory: .negative))
        taskTabOrdering.append(contentsOf: tasksForImageSetBlock(blockNumber: 16, category: .positive, subcategory: .people))
        taskTabOrdering.append(contentsOf: tasksForImageSetBlock(blockNumber: 17, category: .neutral, subcategory: .object))
        taskTabOrdering.append(contentsOf: tasksForImageSetBlock(blockNumber: 18, category: .negative, subcategory: .inconvenience))
        taskTabOrdering.append(contentsOf: tasksForImageSetBlock(blockNumber: 19, category: .negativeArousal, subcategory: .war))
        taskTabOrdering.append(contentsOf: tasksForImageSetBlock(blockNumber: 20, category: .facialExpression, subcategory: .negative))
        taskTabOrdering.append(contentsOf: tasksForImageSetBlock(blockNumber: 21, category: .positive, subcategory: .plants))
        taskTabOrdering.append(contentsOf: tasksForImageSetBlock(blockNumber: 22, category: .neutral, subcategory: .buildings))
        taskTabOrdering.append(contentsOf: tasksForImageSetBlock(blockNumber: 23, category: .negative, subcategory: .frustrating))
        taskTabOrdering.append(contentsOf: tasksForImageSetBlock(blockNumber: 24, category: .negativeArousal, subcategory: .desctruction))
        taskTabOrdering.append(contentsOf: tasksForImageSetBlock(blockNumber: 25, category: .facialExpression, subcategory: .negative))
        
        // Attention Bias Face Task
        taskTabOrdering += [
            TabItem(taskId: "camera_view_attention_bias_face", tabType: .cameraView),
            (TabItem(taskId: "attention_bias_face", tabType: .attentionBiasFaceView, taskTitle: "Attention Bias Face",
                     taskDescription: "Fixate on the white cross or dot when it appears on the screen. There will be various emotional faces displayed on the screen. Freely view the images on the screen",
                     isTaskItem: true))]
        
        //Ending Calibration
        taskTabOrdering += [
            TabItem(taskId: "camera_view_calibration", tabType: .cameraView),
            TabItem(
                taskId: "calibration_view_2",
                tabType: .calibrationView,
                taskTitle: "Calibration",
                taskDescription: "When a ball appears look at it as quickly as possible, and remain staring at it until it disappears.",
                isTaskItem: true
            ),
            TabItem(taskId: "results_view", tabType: .resultsView)]
                            
    }

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
    
    func descriptionForCurrentTab() -> String {
        let currentTab = taskTabOrdering[currentTabIndex]
        return currentTab.taskDescription
    }
    
    func cateogryAndSubcategoryForCurrentTab() -> (TaskBlockCategory?, TaskBlockSubcategory?) {
        let currentTab = taskTabOrdering[currentTabIndex]
        return (currentTab.category, currentTab.subcategory)
    }
    
    func numberOfTasks() -> Int {
        taskTabOrdering.filter({ $0.isTaskItem }).count
    }
    
    func reset() {
        currentTabIndex = 0
        open(taskTabOrdering[currentTabIndex])
    }

    private func open(_ tab: TabItem) {
        DispatchQueue.main.async {
            self.activeTabType = tab.tabType
            self.activeTabBlockNumber = tab.blockNumber
        }
    }
    
    private func tasksForImageSetBlock(blockNumber: Int, category: TaskBlockCategory, subcategory: TaskBlockSubcategory) -> [TabItem] {
        var items: [TabItem] = []
        items.append(TabItem(taskId: "camera_view_affective_image_set_\(blockNumber)", tabType: .cameraView, blockNumber: blockNumber))
        items.append(TabItem(
            taskId: "affective_image_set_\(blockNumber)",
            tabType: .imageView,
            taskTitle: "Image Set - Block \(blockNumber)",
            taskDescription: "8 different images will come across the screen. \n Note: Some of the images may be disturbing.",
            blockNumber: blockNumber,
            category: category,
            subcategory: subcategory,
            isTaskItem: true
        ))
        items.append(TabItem(taskId: "camera_view_plr", tabType: .cameraView))
        items.append(
            TabItem(
                taskId: "plr_view",
                tabType: .plrView,
                taskTitle: "PLR",
                taskDescription: "Stare at the cross for the duration of the task.",
                blockNumber: blockNumber,
                isTaskItem: true))
        return items
    }
}
