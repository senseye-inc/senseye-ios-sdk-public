import Foundation

#if !os(macOS)
import UIKit
import Amplify

struct senseye_ios_sdk {
    var text = "Hello, World!"
}

public class SenseyeSDK {
    
    private var result = "Initial result!"
    var tasks: [String] = ["calibration", "smoothPursuit"]
    
    public init() {
        result = "Post-init result!"
        do {
            try Amplify.configure()
            print("Amplify configured with storage plugin")
        } catch {
            print("Failed to initialize Amplify with \(error)")
        }
    }
    
    public func retreiveResult() -> String {
        return result
    }
    
    @available(iOS 10.0, *)
    public func taskControllerForTasks() -> UIViewController {
        let singleTaskViewController = TaskViewController(nibName: "SingleTaskViewController", bundle: nil)
        singleTaskViewController.taskIdsToComplete = tasks
        return singleTaskViewController
    }
}

#endif
