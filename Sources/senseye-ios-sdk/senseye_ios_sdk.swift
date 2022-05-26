import Foundation
import SwiftUI
#if !os(macOS)
import UIKit
import Amplify
import AWSS3StoragePlugin
import AWSCognitoAuthPlugin
import SwiftUI

protocol SenseyeTaskCompletionDelegate: AnyObject {
    func didCompleteTasksAndReturnResult(result: String)
}
@available(iOS 15.0, *)
public class SenseyeSDK {
    
    let tasks: [String] = ["plr", "calibration", "smoothPursuit"]
    
    weak var delegate: SenseyeTaskCompletionDelegate?
    
    public init() {
        Log.enable()
        Log.debug("SDK Object created!", shouldLogContext: false)
    }
    
    public func initializeSDK() {
        do {
            guard let configurationURL = Bundle.main.url(forResource: "amplifyconfiguration", withExtension: "json") else {
                Log.error("Unable to load amplifyconfiguration.")
                return
            }
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSS3StoragePlugin())
            try Amplify.configure(AmplifyConfiguration.init(configurationFile: configurationURL))
            
            Log.info("Amplify configured with storage plugin")
        } catch {
            Log.error("Failed to initialize Amplify with \(error)")
        }
    }
    
    public func initialViewController() -> UIViewController { loginViewController() }
    
    public func surveyViewController() -> UIViewController {
        let surveyViewController = SurveyViewController(nibName: "SurveyViewController", bundle: nil)
        surveyViewController.taskIdsToComplete = self.tasks
        return surveyViewController
    }
    
    public func taskViewControllerForTasks() -> UIViewController {
        let taskViewController = TaskViewController(nibName: "TaskViewController", bundle: nil)
        taskViewController.taskIdsToComplete = self.tasks
        return taskViewController
    }
    
    /**
    Provides compatibility for UIKit-based applications. LoginView is a SwiftUI view, so we use UIHostController wrapper to let it become UIViewController
     */
    public func loginViewController() -> UIViewController {
        return UIHostingController(rootView: LoginView(authenticationService: AuthenticationService()))
    }
    
    // ReusltsView UI Testing
    
    public func getResultsView() -> some View {
        let resultsView = ResultsView(fileUploadService: FileUploadAndPredictionService())
        return resultsView
    }
}
#endif
