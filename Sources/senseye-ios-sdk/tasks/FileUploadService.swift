//
//  FileUploadService.swift
//  
//
//  Created by Deepak Kumar on 12/15/21.
//

import Foundation
import Amplify

class FileUploadService {
    
    func uploadData(fileUrl: URL) {
        let dataString = fileUrl.lastPathComponent
        let fileNameKey = "\(fileUrl.lastPathComponent).mp4"
        let filename = fileUrl
        do {
            try dataString.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Failed to write to file \(error)")
        }

        let storageOperation = Amplify.Storage.uploadFile(
            key: fileNameKey,
            local: filename,
            progressListener: { progress in
                print("Progress: \(progress)")
            }, resultListener: { event in
                switch event {
                case let .success(data):
                    print("Completed: \(data)")
                case let .failure(storageError):
                    print("Failed: \(storageError.errorDescription). \(storageError.recoverySuggestion)")
                }
            }
        )
    }
    
}
