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
}
