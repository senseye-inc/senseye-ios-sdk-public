import Foundation

#if !os(macOS)
import UIKit

struct senseye_ios_sdk {
    var text = "Hello, World!"
}

public class SenseyeSDK {
    
    private var result = "Initial result!"
    var tasks: [String] = ["calibration", "smoothPursuit"]
    
    public init() {
        result = "Post-init result!"
    }
    
    public func retreiveResult() -> String {
        return result
    }
    
    public func taskControllerForTasks() -> UIViewController {
        let singleTaskViewController = SingleTaskViewController(nibName: "SingleTaskViewController", bundle: nil)
        singleTaskViewController.taskIdsToComplete = tasks
        return singleTaskViewController
    }
}

#endif
