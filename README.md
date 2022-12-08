# Senseye iOS SDK


# Overview

The Senseye SDK allows patients to complete a series of ocular tests using the front facing camera on their iOS device. The SDK records video of the tests and uploads the videos to secure Amazon S3 for storage and analysis. 

    
# Installation

To install the Senseye iOS SDK, follow these steps:

1) Add the Senseye iOS SDK Swift package dependency to your app. You can find it at File > Swift Packages > Add Package Dependency > enter "https://github.com/senseye-inc/senseye-ios-sdk"
2) Import the SDK in your hosting view: import senseye_ios_sdk

#Usage

Once the SDK is properly imported to your hosting view, you can initialize it with the following:
1) var senseyeSDK = SenseyeSDK()

   The initialization takes the following optional parameters:
   userId: String -> Used to map session recording to post-processed reports. If required, please pass in a value that is unique for each participant completing a test session.
   taskIds: [SenseyeSDK.TaskId] -> A list of tasks you will want a participant to complete in each test session. The following tasks are supported:
            1) hrCalibration -> 3 minute baseline recording of the participants Heart Rate using an external BerryMed Pulse Oximeter Device.
            2) firstCalibration -> A participant is asked to follow a small dot that will be displayed at 10 different locations. Each dot is displayed for 2.5 sec, for a total time of 25 sec.  
            3) affectiveImageSets -> A participant is first shown a set of 8 images for 2.5 sec each. Following the set of images, they will be shown a black screen for 5 sec, and then a white screen for 5 sec, all while being asked to focus on a cross in the center of the screen for the full duration of the task. This process of the 8 Image Set and Alternating Black-White screen is repeated 25 times, for a total task time of 12.5 min.
            4) finalCalibration -> A repeat of the previous task in firstCalibration, if required an additonal time.
            5) attentionBiasTest -> A participant is first shown a small cross for 0.5 sec. The screen will then switch to display two images for 2 sec. Finally a small dot will be shown for 0.5 sec. This process of small cross, 2 Images, small dot will repeat for 26 times for a total of 1.3 min. 
2) Following initilization of the SDK variable, display the UI container with the following block in your hosting view:
   senseyeSDK.senseyeTabView()
3) Once the view is diplayed the SDK will complete all required tasks, upload test session recordings, and trigger post-processing. Following upload of recordings the user will see a "Complete Session" button at which point it will be safe to close the hosting view.

# Example

todo --> add some screenshots and examples here for a calibration only app

# Requirements

iOS 15.0 or later
Xcode 13.0 or later
Fully supported devices for post-processing -> iPhone 11 Pro Max or later            
    
# Unit Tests

To run the tests, ensure you have an iOS Simulator selected as your build destination, tests won't compile on macOS. To select a build destination, type `control + shift + 0` and select a device. Run all tests with `command + U` or press `command 6` to open the test naviagtor and select which tests you would like to run.

# Logging

The `Log` enum found under the SDK is a convenience logger. To emit a log message, use appropriate method of `Log`.

Before emitting a log, 1) enable logging and 2) set a log level within scope. Log categories are: debug, info, warn, and error.

2) Log levels control which category of logs are emitted. There are two methods to define log levels: The `dynamicLogLevel` variable is changeable at runtime and set inline with code. The level definable at build time is in the `GCC_PREPROCESSOR_DEFINITIONS` build setting. There you can add a `DD_LOG_LEVEL` defined to the desired log level. Both levels have a default of `DDLogLevelAll`.

