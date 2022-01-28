import Foundation

#if !os(macOS)
import UIKit
import Amplify
import AWSS3StoragePlugin
import AWSCognitoAuthPlugin


protocol SenseyeTaskCompletionDelegate: class {
    func didCompleteTasksAndReturnResult(result: String)
}

public class SenseyeSDK {
    
    var tasks: [String] = ["calibration", "smoothPursuit"]
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
    
    @available(iOS 10.0, *)
    public func taskControllerForTasks() -> UIViewController {
        let singleTaskViewController = TaskViewController(nibName: "SingleTaskViewController", bundle: nil)
        singleTaskViewController.taskIdsToComplete = tasks
        return singleTaskViewController
    }
}

#endif
