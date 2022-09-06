//
//  File.swift
//  
//
//  Created by Frank Oftring on 4/7/22.
//

import SwiftUI
import Combine

@available(iOS 14.0, *)
class ResultsViewModel: ObservableObject {
    
    init(fileUploadService: FileUploadAndPredictionServiceProtocol) {
        self.fileUploadService = fileUploadService
        addSubscribers()
    }
    
    var fileUploadService: FileUploadAndPredictionServiceProtocol
    var cancellables = Set<AnyCancellable>()
    
    @Published var uploadProgress: Double = 0.0
    @Published var isFinished: Bool = false
    
    private var taskCount: Double {
        Double(fileUploadService.taskCount)
    }
    
    func addSubscribers() {
        fileUploadService.uploadProgressPublisher
            .sink(receiveValue: { [weak self] newUploadProgress in
                guard let self = self else { return }
                let updatedUploadProgress = newUploadProgress / self.taskCount
                self.uploadProgress = updatedUploadProgress.rounded(toPlaces: 2)
                Log.info("UploadProgress: \(self.uploadProgress)", shouldLogContext: true)
            })
            .store(in: &cancellables)
        
        fileUploadService.uploadsAreCompletePublisher
            .sink { completed in
                if completed {
                    self.isFinished = true
                }
            }
            .store(in: &cancellables)
    }
    
    func reset() {
        uploadProgress = 0.0
        isFinished = false
        fileUploadService.reset()
    }
}
