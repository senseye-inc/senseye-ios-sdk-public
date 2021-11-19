import Foundation

#if !os(macOS)
import UIKit

struct senseye_ios_sdk {
    var text = "Hello, World!"
}

public class SenseyeSDK {
    
    private var result = "Initial result!"
    
    public init() {
        result = "Post-init result!"
    }
    
    public func retreiveResult() -> String {
        return result
    }
    
    public func taskController() -> UIViewController {
        let singleTaskViewController = SingleTaskViewController(nibName: "SingleTaskViewController", bundle: nil)
        return singleTaskViewController
    }
}

#endif
