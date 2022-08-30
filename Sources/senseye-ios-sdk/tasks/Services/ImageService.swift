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
    @Published var imagesForBlock: [Image] = []
    @Published var finishedDownloadingImages: Bool = false
    
    private let fileManager: FileManager
    private let folderName = "affective_images"
    private var cancellables = Set<AnyCancellable>()
    
    private var affectiveImageSets: [Int: AffectiveImageSet] = [
        2: AffectiveImageSet(category: .positive, imageIds: ["fire_9", "stream", "leaves_3", "desert_3", "acorns_1", "desert_2", "fire_7", "water"]),
        3: AffectiveImageSet(category: .neutral, imageIds: ["puppies_1", "cat_5", "bird_1", "panda_5", "chipmunk_1", "dog_4", "seal_1", "horse_1"])
    ]
    
    private var allImageNames : [String] {
        let imageNames = affectiveImageSets.flatMap { (key: Int, value: AffectiveImageSet) in
            return value.imageIds
        }
        return imageNames
    }
    
    func refreshImages() {
        self.getImages()
    }
    
    private func getImages() {
        let allImages = allImageNames
        if let savedImages = fileManager.getImages(imageNames: allImages, folderName: folderName) {
            Log.info("Fetching Saved Image!")
            self.senseyeImages = savedImages
        } else {
            Log.info("Downloading images!")
            downloadImagesToFileManager()
        }
    }
    
    func updateImagesForBlock(blockNumber: Int) {
        guard let imageSetIds = affectiveImageSets[blockNumber]?.imageIds else {
            return
        }
        let senseyeImageFilesForIds = senseyeImages.filter { senseyeImage in
            imageSetIds.contains(senseyeImage.imageName)
        }
        let imageSetForBlock = senseyeImageFilesForIds.map { Image(uiImage: $0.image) }
        self.imagesForBlock = imageSetForBlock
    }
    
    private func downloadImagesToFileManager() {
        for imageName in allImageNames {
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
                    senseyeImages = senseyeImages.reorder(by: allImageNames)
                }
                .store(in: &cancellables)
        }
    }
}

enum AffectiveImageCategory {
    case positive
    case neutral
    case negative
    case negativeArousal
    case facialExpression
}
struct AffectiveImageSet {
    let category: AffectiveImageCategory
    let imageIds: [String]
}
