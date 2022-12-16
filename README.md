# Senseye iOS SDK


# Overview

The Senseye SDK allows participants to complete a series of ocular tasks using the front facing camera on their iOS device. A series of tasks comprises a completed session. The SDK records video of the participant performing the task and uploads the videos to secured Amazon S3 storage for analysis. 

    
# Installation and Permissions

To install the Senseye iOS SDK, follow these steps:

1) Add the Senseye iOS SDK Swift package dependency to your app. You can find it at File > Swift Packages > Add Package Dependency > enter "https://github.com/senseye-inc/senseye-ios-sdk-public"
2) Import the SDK in your hosting view: `import senseye_ios_sdk`
3) Usage of the SDK requires both Bluetooth and Camera Permissions. The iOS Platform requires them to be added to your App's Info.plist file. Below is a screenshot of adding the permissions to a sample app:
![permissions updates for ReadME iOS SDK (1)](https://user-images.githubusercontent.com/5391849/207956888-88b7c70d-fd24-4012-a6f6-4975f908031f.png)


# Usage

## 1. Initialize

Once the SDK is properly imported to your hosting view, you can initialize it with the following:
   
   ```swift
   var senseyeSDK = SenseyeSDK()
   ```
   or 
   ```swift
   var senseyeSDK = SenseyeSDK(userID: String, taskIDs [SenseyeSDK.TaskID])
   ```

   The initialization takes the following optional parameters:
   
   - `userId: String` -> Used to map session recording to post-processed reports. If required by your app, pass in a value that is unique to each participant completing a test session.
   
   - `taskIds: [SenseyeSDK.TaskId]` -> A list of tasks you will want a participant to complete in each test session. 
   
      The following tasks are supported:

      1) `hrCalibration` -> 3 minute baseline recording of the participant's Heart Rate using an external BerryMed Pulse Oximeter Device.
      2) `firstCalibration` -> A participant is instructed to follow a small dot that will be displayed at 10 different locations. Each dot is displayed  for 2.5 sec, for a total task time of 25 sec.  
      3) `affectiveImageSets` -> A participant is first shown a set of 8 images for 2.5 sec each. They are allowed to look anywhere within the images being displayed. Following the set of images, they are instructed to view a screen with cross fixation point. This process of the 8 Image Set and Alternating Black-White screen is repeated 25 times, for a total task time of 12.5 min.
      4) `finalCalibration` -> A repeat of the previous task in firstCalibration, if required an additional time.
      5) `attentionBiasTest` -> A participant is instructed to view a cross fixation point for 0.5 sec. The screen will then switch to display two vertically stacked images for 2 sec, after which a small dot will be shown for 0.5 sec. This process of the fixation point, two images, and small dot will repeat 26 times for a total of 1.3 min. 

   - `shouldCollectSurveyInfo: Bool` -> The app is able to collect basic demographic info for any participant using the app. Currently we collect the      following fields: Age, Gender, and Eye Color. 

   - `requiresAuth` -> If we have provided you with unique account login for each participant set this field to `true`, otherwise omit this from the SDK intialization. 
   - `databaseLocation` -> Use this field if we have provided you with a custom databaseLocation for storage, otherwise omit this from the SDK initialization. 
   - `shouldUseFirebaseLogging` -> If you would like to use Firebase for custom logging and reporting from inside the SDK set this to `true`. Otherwise omit this from the SDK Initialization. See the bottom of the `Logging` instruction for proper set up of Firebase/Crashlytics. 

## 2. Display Container
Following initilization of the SDK variable, display the UI container with the following block in your hosting view:
   `senseyeSDK.senseyeTabView()`

## 3. Run Tasks
Once the view is diplayed the SDK will complete all required tasks, upload test session recordings, and trigger post-processing. Following upload of recordings the user will see a "Complete Session" button at which point it will be safe to close the hosting view. See the screenshot below:

<img width="346" alt="Complete Session screenshot" src="https://user-images.githubusercontent.com/5391849/206341149-d0025c14-f157-4c6c-8576-373aa649809b.png">

# Example

The below is a simple app that initializes the SDK and displayed the UI in a hosting Swift UI view. From the initialization constructor, we define a single Calibration task to be completed. 

```
import SwiftUI
import senseye_ios_sdk

@available(iOS 15.0, *)
@main
struct Senseye_DemoApp: App {

    @Environment(\.scenePhase) var scenePhase
    var senseyeSDK: SenseyeSDK = SenseyeSDK(userId: "senseye_diagnostic", taskIds: [.firstCalibration])
    let initialBrightness = UIScreen.main.brightness
    
    var body: some Scene {
        WindowGroup {
            EntryView(senseyeSDK: senseyeSDK)
        }
        .onChange(of: scenePhase) { newScene in
            if newScene == .active {
                DispatchQueue.main.async {
                    UIScreen.main.brightness = 1.0
                    UIApplication.shared.isIdleTimerDisabled = true
                }
            } else {
                DispatchQueue.main.async {                
                    UIScreen.main.brightness = initialBrightness
                    UIApplication.shared.isIdleTimerDisabled = false
                }
            }
        }
    }
}
```
The SDK instance is injected into the initialization of `EntryView`, which conforms to the View protocol, and its `var body` simply returns `senseyeTabView()`.

```
import SwiftUI
import senseye_ios_sdk


@available(iOS 15.0, *)
struct EntryView: View {

    var senseyeSDK: SenseyeSDK
    init(senseyeSDK: SenseyeSDK) {
        self.senseyeSDK = senseyeSDK
    }

    var body: some View {
        senseyeSDK.senseyeTabView()
    }
}
```

# Requirements

- iOS 15.0 or later
- Xcode 13.0 or later
- Fully supported devices for post-processing -> iPhone 11 Pro Max or later            
    
# Unit Tests

To run the tests, ensure you have an iOS Simulator selected as your build destination, tests won't compile on macOS. To select a build destination, type `control + shift + 0` and select a device. Run all tests with `command + U` or press `command 6` to open the test naviagtor and select which tests you would like to run.

# Logging

The `Log` enum found under the SDK is a convenience logger. To emit a log message, use appropriate method of `Log`.

Before emitting a log, 1) enable logging and 2) set a log level within scope. Log categories are: debug, info, warn, and error.

2) Log levels control which category of logs are emitted. There are two methods to define log levels: The `dynamicLogLevel` variable is changeable at runtime and set inline with code. The level definable at build time is in the `GCC_PREPROCESSOR_DEFINITIONS` build setting. There you can add a `DD_LOG_LEVEL` defined to the desired log level. Both levels have a default of `DDLogLevelAll`.

If you would like to incorporate Firebase crashyltics logs for calls from the SDK, please add your GoogleService-Info file to the top level of the project, and set shouldUseFirebaseLogging = true in the SDK initialization constructor. 

Below is a screenshot for adding the Firebase initialization file to a sample app:
![google-services-instruction-sdk](https://user-images.githubusercontent.com/5391849/207928576-099610e1-bbff-4e13-8411-ddf33eac31b5.png)
