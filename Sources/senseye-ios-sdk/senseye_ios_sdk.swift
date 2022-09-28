import Foundation
import SwiftUI
#if !os(macOS)
import UIKit
import Amplify
import AWSS3StoragePlugin
import AWSCognitoAuthPlugin
import Firebase
import SwiftUI

protocol SenseyeTaskCompletionDelegate: AnyObject {
    func didCompleteTasksAndReturnResult(result: String)
}

public class SenseyeSDK {
    
    weak var delegate: SenseyeTaskCompletionDelegate?

    public init() {
        Log.enable()
        Log.debug("SDK Object created!", shouldLogContext: false)
        initializeSDK()
    }
    
    private func initializeSDK() {
        do {
            guard let configurationURL = Bundle.module.url(forResource: "amplifyconfiguration", withExtension: "json") else {
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

        // Use the Firebase library to configure APIs.
        FirebaseApp.configure()
    }

    @MainActor public func senseyeTabView() -> some View {
        let authenticationService = AuthenticationService()
        let fileUploadService = FileUploadAndPredictionService(authenticationService: authenticationService)
        let cameraService = CameraService(authenticationService: authenticationService, fileUploadService: fileUploadService)
        let imageService = ImageService(authenticationService: authenticationService)
        return SenseyeTabView()
            .environmentObject(authenticationService)
            .environmentObject(fileUploadService)
            .environmentObject(imageService)
            .environmentObject(cameraService)
    }
    
}
#endif
