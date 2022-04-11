import Foundation
import SwiftUI
#if !os(macOS)
import UIKit
import Amplify
import AWSS3StoragePlugin
import AWSCognitoAuthPlugin


protocol SenseyeTaskCompletionDelegate: AnyObject {
    func didCompleteTasksAndReturnResult(result: String)
}

@available(iOS 14.0, *)
public class SenseyeSDK {
    
    var tasks: [String] = ["plr", "calibration", "smoothPursuit"]
    weak var delegate: SenseyeTaskCompletionDelegate?
    
    public init() {
        print("SDK Object created!")
    }
    
    public func initializeSDK() {
        do {
            guard let configurationURL = Bundle.module.url(forResource: "amplifyconfiguration", withExtension: "json") else {
                return
            }
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSS3StoragePlugin())
            try Amplify.configure(AmplifyConfiguration.init(configurationFile: configurationURL))
            
            print("Amplify configured with storage plugin")
        } catch {
            print("Failed to initialize Amplify with \(error)")
        }
    }
    
    public func taskControllerForTasks() -> UIViewController {
        let surveyViewController = SurveyViewController(nibName: "SurveyViewController", bundle: nil)
        surveyViewController.taskIdsToComplete = tasks
        return surveyViewController
    }
    
    // ReusltsView UI Testing
    
    public func getResultsView() -> some View {
            let resultsView = ResultsView(taskViewController: TaskViewController())
            return resultsView
        }
}

#endif
