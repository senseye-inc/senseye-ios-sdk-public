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
    
    private var fullImageSet: [SenseyeImage] = []
    @Published var imagesForBlock: [(String, Image)] = []
    
    private let fileManager: FileManager
    private let folderName = "affective_images"
    private var cancellables = Set<AnyCancellable>()
    
    private var affectiveImageSets: [Int: AffectiveImageSet] = [
        1: AffectiveImageSet(category: .positive, imageIds: ["beach_1", "beach_2", "beach_6", "lake_2", "lake_7", "rainbow_1", "outside_5", "sunset_4"])
    ]
    
    private var allImageNames : [String] {
        let imageNames = affectiveImageSets.flatMap { (key: Int, value: AffectiveImageSet) in
            return value.imageIds
        }
        return imageNames
    }
    
    private func getImages() {
        if let savedImages = fileManager.getImages(imageNames: allImageNames, folderName: folderName) {
            Log.info("Fetching Saved Image!")
            self.fullImageSet = savedImages
        } else {
            Log.info("Downloading images!")
            downloadImagesToFileManager()
        }
    }
    
    func updateImagesForBlock(blockNumber: Int) {
        guard let imageSetIds = affectiveImageSets[blockNumber]?.imageIds else {
            return
        }
        let senseyeImageFilesForIds = fullImageSet.filter { senseyeImage in
            imageSetIds.contains(senseyeImage.imageName)
        }
        let imageSetForBlock = senseyeImageFilesForIds.map { ($0.imageName,Image(uiImage: $0.image)) }
        self.imagesForBlock = imageSetForBlock
    }
    
    private func downloadImagesToFileManager() {
        for blockNumber in affectiveImageSets.keys {
            let s3ImageFolder = "ptsd_image_sets/block_\(blockNumber)"
            let blockValue = affectiveImageSets[blockNumber]
            guard let imageIdsForBlock = blockValue?.imageIds else {
                return
            }
            for imageName in imageIdsForBlock {
                let s3ImageKey = "\(s3ImageFolder)/\(imageName).png"
                Amplify.Storage.downloadData(key: s3ImageKey).resultPublisher
                    .receive(on: DispatchQueue.main)
                    .compactMap({UIImage(data: $0)})
                    .sink { _ in
                    } receiveValue: { [weak self] image in
                        guard let self = self else {
                            return
                        }
                        Log.info("completed download for image: \(imageName)")
                        self.fileManager.saveImage(image: image, imageName: imageName, folderName: self.folderName)
                        let newSenseyeImage = SenseyeImage(image: image, imageName: imageName)
                        self.fullImageSet.append(newSenseyeImage)
                    }.store(in: &cancellables)
            }
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
