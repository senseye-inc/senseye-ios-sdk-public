//
//  CameraViewModel.swift
//  
//
//  Created by Bobby Srisan on 10/12/22.
//
import Foundation
import Combine

class CameraViewModel: ObservableObject {
    private var cameraPreviewTimer: Timer? = nil
    private var overlayTimer: Timer? = nil
    private let taskTiming: Double = 1.0
    private var currentOverlayInterval: Int = 0
    private var currentCameraPreviewTimeInterval: Int = 0

    @Published var isShowingOverlay: Bool = true
    @Published var shouldProceedToNextTab: Bool = false
    @Published var callToActionText: String = ""
    var shouldShowFacialComplianceLabel: Bool {
        return self.fileUploadService.isDebugModeEnabled
    }

    private var cancellables: Set<AnyCancellable> = []
    private let fileUploadService: FileUploadAndPredictionServiceProtocol

    init(fileUploadService: FileUploadAndPredictionServiceProtocol) {
        self.fileUploadService = fileUploadService
    }
    
    func onAppear() {
        shouldProceedToNextTab = false
        isShowingOverlay = true
        callToActionText =  String(format: "Double tap to start".localizedString)
    }

    func onDisappear() {
        stopCountdown(for: &overlayTimer)
        stopCountdown(for: &cameraPreviewTimer)
    }

    private func addSubscribers() {
        $isShowingOverlay
            .receive(on: DispatchQueue.main)
            .sink { [weak self] showingOverlay in
                guard let self = self else {
                    Log.info("Unable to capture self", shouldLogContext: true)
                    return
                }
                if !showingOverlay {
                    self.startPreviewTimerCountdown()
                } else {
                    self.stopCountdown(for: &self.cameraPreviewTimer)
                }
            }
            .store(in: &cancellables)
    }

    private func onAppearInitializeTimers() {
        currentOverlayInterval = Timing.instructionTimeout
        currentCameraPreviewTimeInterval = Timing.cameraPreviewTimeout
        cameraPreviewTimer = nil
        overlayTimer = nil
        startOverlayTimerCountdown()
    }

    private func startOverlayTimerCountdown() {
        if overlayTimer == nil {
            Log.info("CameraViewModel creating overaly timer")
            overlayTimer = Timer.scheduledTimer(withTimeInterval: taskTiming, repeats: true) { [weak self] timer in
                guard let self = self else {
                    Log.info("Unable to capture self", shouldLogContext: true)
                    return
                }
                self.currentOverlayInterval -= 1

                if self.currentOverlayInterval == 0 {
                    self.stopCountdown(for: &self.overlayTimer)
                    self.isShowingOverlay = false
                }
            }
        }
    }

    private func startPreviewTimerCountdown() {

        if cameraPreviewTimer == nil {
            Log.info("CameraViewModel creating preview timer")
            cameraPreviewTimer = Timer.scheduledTimer(withTimeInterval: taskTiming, repeats: true) { [weak self] timer in
                guard let self = self else {
                    Log.info("Unable to capture self", shouldLogContext: true)
                    return
                }
                self.currentCameraPreviewTimeInterval -= 1
                self.callToActionText = String(format: "Task starts in %ds".localizedString, self.currentCameraPreviewTimeInterval)

                if self.currentCameraPreviewTimeInterval == 0 {
                    self.stopCountdown(for: &self.cameraPreviewTimer)
                    self.shouldProceedToNextTab = true
                }
            }
        }
    }

    private func stopCountdown(for timer: inout Timer?) {
        if (timer != nil) {
            timer?.invalidate()
            Log.info("CameraViewModel Timer Cancelled")
            timer = nil
        }
    }
}
