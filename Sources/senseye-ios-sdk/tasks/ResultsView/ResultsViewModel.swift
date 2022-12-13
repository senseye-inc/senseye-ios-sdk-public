//
//  File.swift
//  
//
//  Created by Frank Oftring on 4/7/22.
//

import SwiftUI
import Combine

class ResultsViewModel: ObservableObject {
    
    init(fileUploadService: FileUploadAndPredictionServiceProtocol) {
        self.fileUploadService = fileUploadService
        addSubscribers()
    }
    
    var fileUploadService: FileUploadAndPredictionServiceProtocol
    var cancellables = Set<AnyCancellable>()

    private var delayedResultTimer: Timer? = nil
    private let delayedResultTiming: Double = 60.0
    
    @Published var uploadProgress: Double = 0.0
    @Published var isFinished: Bool = false
    @Published var hasResultCompleteTimerElapsed = false

    func addSubscribers() {
        fileUploadService.uploadProgressPublisher
            .combineLatest(fileUploadService.isFinishedPublisher)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progressCount, isFinished in
                guard let self = self else { return }
                self.uploadProgress = Double(progressCount)/Double(self.fileUploadService.taskCount)
                self.isFinished = isFinished
            }
            .store(in: &cancellables)
    }
    
    func reset() {
        delayedResultTimer = nil
        hasResultCompleteTimerElapsed = false
        uploadProgress = 0.0
        isFinished = false
        fileUploadService.reset()
    }

    func onAppear() {
        startDelayedResultTimer()
    }
    
    private func startDelayedResultTimer() {
        if (delayedResultTimer == nil) {
            delayedResultTimer = Timer.scheduledTimer(withTimeInterval: delayedResultTiming, repeats: false) { [weak self] _ in
                guard let self = self else {
                    Log.info("Unable to capture self", shouldLogContext: true)
                    return
                }
                self.hasResultCompleteTimerElapsed = true
                self.stopDelayedResultTimer()
            }
        }
    }

    private func stopDelayedResultTimer() {
        if (delayedResultTimer != nil) {
            delayedResultTimer?.invalidate()
            delayedResultTimer = nil
        }
    }
}
