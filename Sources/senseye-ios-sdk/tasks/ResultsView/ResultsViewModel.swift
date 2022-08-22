//
//  File.swift
//  
//
//  Created by Frank Oftring on 4/7/22.
//

import Foundation
import Combine

@available(iOS 14.0, *)
class ResultsViewModel: ObservableObject {
    
    init(fileUploadService: FileUploadAndPredictionServiceProtocol) {
        self.fileUploadService = fileUploadService
        getUploadProgress()
    }
    
    var fileUploadService: FileUploadAndPredictionServiceProtocol
    var cancellables = Set<AnyCancellable>()
    
    @Published var error: Error?
    @Published var uploadProgress: Double = 0.0

    func getUploadProgress() {
        fileUploadService.uploadProgressPublisher
            .sink { newUploadProgress in
                let updatedUploadProgress = newUploadProgress/self.fileUploadService.numberOfUploads
                self.uploadProgress = updatedUploadProgress
            }
            .store(in: &cancellables)
    }
    
    func uploadJsonSessionFile() {
        self.fileUploadService.uploadSessionJsonFile()
    }
}
