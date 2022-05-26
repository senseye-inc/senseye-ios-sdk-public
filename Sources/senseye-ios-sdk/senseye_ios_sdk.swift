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
        print("SDK Object created!")
    }
    
    public func initializeSDK() {
        do {
            guard let configurationURL = Bundle.module.url(forResource: "amplifyconfiguration", withExtension: "json") else {
                print("Unable to load amplifyconfiguration.")
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
    
    public func initialViewController() -> UIViewController { loginViewController() }
    
    public func surveyViewController() -> UIViewController {
        if let surveyViewController: SurveyViewController = Bundle.module.loadNibNamed("SurveyViewController", owner: nil, options: nil)?.first as? SurveyViewController {
            return surveyViewController
        }
        return UIViewController()
    }
    
    public func taskViewControllerForTasks() -> UIViewController {
        if let taskViewController: TaskViewController = Bundle.module.loadNibNamed("TaskViewController", owner: nil, options: nil)?.first as? TaskViewController {
            taskViewController.taskIdsToComplete = self.tasks
            return taskViewController
        }
        return UIViewController()
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
