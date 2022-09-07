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
        1: AffectiveImageSet(category: .positive, imageIds: ["beach_1", "beach_2", "beach_6", "lake_2", "lake_7", "rainbow_1", "outside_5", "sunset_4"]),
        2: AffectiveImageSet(category: .neutral, imageIds: ["acorns_1", "desert_2", "desert_3", "fire_7", "fire_9", "leaves_3", "stream", "water"]),
        3: AffectiveImageSet(category: .negative, imageIds: ["carsplash2", "coffee_spill2", "dog_destroy", "gumshoe", "icecream", "kidmess", "spiltmilk", "trash"]),
        4: AffectiveImageSet(category: .negativeArousal, imageIds: ["car_crash1", "car_crash2", "car_crash3", "car_crash4", "car_crash5", "car_crash6", "car_crash7", "car_crash8"]),
        5: AffectiveImageSet(category: .facialExpression, imageIds: ["negative1", "negative2", "negative3", "negative4", "neutral1", "neutral2","positive1", "positive2"]),
        6: AffectiveImageSet(category: .positive, imageIds: ["baby_10", "baby_2", "baby_8", "baby_9", "birthday_2", "children_1", "cute_baby_1", "dessert_8", "gazing_6"]),
        7: AffectiveImageSet(category: .neutral, imageIds: ["biking_1", "collaboration_1", "farmer_1", "gathering_6", "guitar_4", "man_red_2", "man_sleeping", "vintage"]),
        8: AffectiveImageSet(category: .negative, imageIds: ["crowded_sub2", "flattire", "flightdelay5", "log", "lost_dog2", "redlight", "stolen_bike", "traffic"]),
        9: AffectiveImageSet(category: .negativeArousal, imageIds: ["animal_carcass_1", "animal_carcass_6", "trauma_animal1", "trauma_animal2", "trauma_animal4", "trauma_animal6", "trauma_animal7", "trauma_animal8"]),
        10: AffectiveImageSet(category: .facialExpression, imageIds: ["negative5", "negative6", "negative7", "negative8", "neutral3", "neutral3", "neutral4", "positive3", "positive4"])
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
