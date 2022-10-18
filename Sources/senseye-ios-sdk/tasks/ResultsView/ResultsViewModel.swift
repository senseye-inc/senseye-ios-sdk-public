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
    
    @Published var uploadProgress: Double = 0.0
    @Published var isFinished: Bool = false
    
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
        uploadProgress = 0.0
        isFinished = false
        fileUploadService.reset()
    }
}
