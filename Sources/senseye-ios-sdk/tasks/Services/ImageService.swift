//
//  ImageService.swift
//  
//
//  Created by Frank Oftring on 7/29/22.
//

import SwiftUI
import Combine
import Amplify

@available(iOS 14.0, *)
class ImageService {
    
    init() {
        self.fileManager = FileManager.default
        self.getImages()
    }
    
    @Published var senseyeImages: [SenseyeImage] = []
    
    private let fileManager: FileManager
    private let folderName = "affective_images"
    private var cancellables = Set<AnyCancellable>()
    
    let affectiveImageNames: [String] = ["fire_9", "stream", "leaves_3", "desert_3", "acorns_1", "desert_2", "fire_7", "water"]
    
    private func getImages() {
        if let savedImages = fileManager.getImages(imageNames: affectiveImageNames, folderName: folderName) {
            Log.info("Fetching Saved Image!")
            self.senseyeImages = savedImages
        } else {
            Log.info("Downloading images!")
            downloadImagesToFileManager()
        }
    }
    
    private func downloadImagesToFileManager() {
        for imageName in affectiveImageNames {
            let s3imageKey = "ptsd_image_sets/\(imageName).png"
            Log.info("Starting Download for Image: \(imageName)!")
            
            Amplify.Storage.downloadData(key: s3imageKey).resultPublisher
                .receive(on: DispatchQueue.main)
                .compactMap({ UIImage(data: $0) })
                .sink { _ in
                    
                } receiveValue: { [self] image in
                    Log.info("completed download for image: \(imageName)")
                    fileManager.saveImage(image: image, imageName: imageName, folderName: folderName)
                    let newSenseyeImage = SenseyeImage(image: image, imageName: imageName)
                    senseyeImages.append(newSenseyeImage)
                    senseyeImages = senseyeImages.reorder(by: affectiveImageNames)
                }
                .store(in: &cancellables)
        }
    }
    
}
