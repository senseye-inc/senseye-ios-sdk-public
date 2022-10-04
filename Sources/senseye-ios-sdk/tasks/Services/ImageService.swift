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
class ImageService: ObservableObject {
    private var authenticationService: AuthenticationService?

    init(authenticationService: AuthenticationService) {
        self.fileManager = FileManager.default
        self.authenticationService = authenticationService
        addSubscribers()
    }
    
    private var fullImageSet: [SenseyeImage] = []
    @Published var imagesForBlock: [(String, Image)] = []
    @Published var finishedDownloadingAllImages = false
    @Published var currentDownloadCount: String  = ""
    
    private let fileManager: FileManager
    private let folderName = "affective_images"
    private var cancellables = Set<AnyCancellable>()
    private var startedInitialDownload = false
    
    var allDownloadsFinished: Bool {
        fullImageSet.count >= allImageNames.count
    }
    
    private var affectiveImageSets: [Int: AffectiveImageSet] = [
        1: AffectiveImageSet(category: .positive, imageIds: ["beach_1", "beach_2", "beach_6", "lake_2", "lake_7", "outside_5", "rainbow_1", "sunset_4"]),
        2: AffectiveImageSet(category: .neutral, imageIds: ["acorns_1", "pinecone", "beach", "fire_7", "fire_9", "leaves_3", "leaves_1", "snow_storm"]),
        3: AffectiveImageSet(category: .negative, imageIds: ["carsplash2", "garbage_dump_4", "dog_destroy", "gumshoe", "icecream", "kidmess", "spiltmilk", "trash"]),
        4: AffectiveImageSet(category: .negativeArousal, imageIds: ["car_crash1", "car_crash2", "car_crash3", "car_crash4", "car_crash5", "car_crash6", "car_crash7", "car_crash8"]),
        5: AffectiveImageSet(category: .facialExpression, imageIds: ["negative1", "negative2", "negative3", "negative4", "neutral1", "neutral2", "positive1", "positive2"]),
        6: AffectiveImageSet(category: .positive, imageIds: ["baby_8b", "baby_8", "baby_9", "birthday_2", "children_1", "cute_baby_1", "dessert_8", "gazing_6"]),
        7: AffectiveImageSet(category: .neutral, imageIds: ["gazing_7", "gazing_4", "girl_on_phone", "standing_man", "gathering_6", "man_red_2", "man_sleeping", "vintage"]),
        8: AffectiveImageSet(category: .negative, imageIds: ["crowded_sub2", "flattire", "flightdelay5", "log", "split_coffe_2", "hurt_ankle", "baby_crying_2", "traffic"]),
        9: AffectiveImageSet(category: .negativeArousal, imageIds: ["dog_24", "animal_carcass_6", "dog_26", "trauma_animal3", "trauma_animal4", "trauma_animal6", "trauma_animal1", "trauma_animal8"]),
        10: AffectiveImageSet(category: .facialExpression, imageIds: ["negative5", "negative6", "negative7", "negative8", "neutral3", "neutral4", "positive3", "positive4"]),
        11: AffectiveImageSet(category: .positive, imageIds: ["bird_1", "cat_5", "chipmunk_1", "dog_4", "horse_1", "panda_5", "puppies_1", "seal_1"]),
        12: AffectiveImageSet(category: .neutral, imageIds: ["bark_1", "bricks_1", "bark_2", "fence_1", "bark_4", "paper_4", "sidewalk_3", "wall_5"]),
        13: AffectiveImageSet(category: .negative, imageIds: ["broken_glasses", "broken_cellphone", "broken_mug3", "broken_window2", "cracked_windsh", "broken_phone", "broken_plate", "spill"]),
        14: AffectiveImageSet(category: .negativeArousal, imageIds: ["abused_child1", "abused_face", "burned_bodies", "dead_bodies1", "injury2", "injury3", "bloody_knife_1", "dead_bodies_3"]),
        15: AffectiveImageSet(category: .facialExpression, imageIds: ["negative10", "negative11", "negative12", "negative9", "positive5", "positive6", "positive7", "positive8"]),
        16: AffectiveImageSet(category: .positive, imageIds: ["couple_7", "dancing_9", "friends_2", "parade_1", "picnic_1", "wedding_1", "wedding_2", "yoga_5"]),
        17: AffectiveImageSet(category: .neutral, imageIds: ["bench", "fire_hydrant_2", "boat_1", "cotton_swabs_2", "keyboard_2", "lime_tree", "bottle_1", "watch_3"]),
        18: AffectiveImageSet(category: .negative, imageIds: ["badparking", "bathroom", "battery2", "empty_tp3", "toilet", "jumpcar", "roadclosed", "sockburr"]),
        19: AffectiveImageSet(category: .negativeArousal, imageIds: ["ambulance_1", "explosion_5", "war5", "war8", "war1", "war3", "war6", "war7"]),
        20: AffectiveImageSet(category: .facialExpression, imageIds: ["negative13", "negative14", "negative15", "negative16", "positive10", "positive11", "positive12", "positive9"]),
        21: AffectiveImageSet(category: .positive, imageIds: ["bridge_1", "flower_1", "flower_3", "flowers_2", "flowers_5", "succulent_1", "sunflower_1", "wedding_ring_1"]),
        22: AffectiveImageSet(category: .neutral, imageIds: ["building_1", "building_2", "building_5", "building_6", "building_7", "door", "house_1", "house"]),
        23: AffectiveImageSet(category: .negative, imageIds: ["soldiers_3", "soldiers_4", "soldiers_6", "soldiers_8", "soldiers_9", "war_4", "cemetery_3", "cemetery_5"]),
        24: AffectiveImageSet(category: .negativeArousal, imageIds: ["destruction7", "destruction2", "destruction3", "destruction10", "destruction5", "destruction6", "destruction7", "destruction8"]),
        25: AffectiveImageSet(category: .facialExpression, imageIds: ["negative17", "negative18", "negative19", "negative20", "positive13", "positive14", "positive15", "positive16"])
    ]
    
    private var allImageNames : [String] {
        let imageNames = affectiveImageSets.flatMap { (key: Int, value: AffectiveImageSet) in
            return value.imageIds
        }
        return imageNames
    }

    func addSubscribers() {
        guard let authenticationService = self.authenticationService else { return }

        authenticationService.$isSignedIn
            .debounce(for: .milliseconds(10), scheduler: RunLoop.main)
            .receive(on: DispatchQueue.global(qos: .utility))
            .sink { [weak self] isSignedIn in
                guard let self = self else {return}
                if isSignedIn && !self.startedInitialDownload {
                    self.startedInitialDownload = true
                    self.getImages()
                }
            }
            .store(in: &cancellables)
    }
    
    private func getImages() {
        let allPreviouslyDownloadImages = fileManager.getImages(imageNames: allImageNames, folderName: folderName)
        let allPreviouslyDownloadedImageKeys = Set(allPreviouslyDownloadImages.map { $0.imageName })
        self.fullImageSet = allPreviouslyDownloadImages
        let fullImageNameSet = Set(allImageNames)
        let additionalImageIds = fullImageNameSet.subtracting(allPreviouslyDownloadedImageKeys)
        if (!additionalImageIds.isEmpty) {
            downloadSpecificImages(imageIds: Array(additionalImageIds))
            Log.info("Need to download images -> \(additionalImageIds)")
            Log.info("Additional Images Count: \(additionalImageIds.count)")
        } else {
            Log.info("All downloads finished perviously")
            self.finishedDownloadingAllImages = true
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
    
    private func downloadSpecificImages(imageIds: [String]) {
        for (blockNumber, imageSet) in affectiveImageSets {
            let s3ImageFolder = "ptsd_image_sets/block_\(blockNumber)"
            let imagesToDownloadFromBlock: [(String, String)] = imageSet.imageIds.filter { imageIds.contains($0) }.map {
                ($0, "\(s3ImageFolder)/\($0).png")
            }
            downloadImagesToFileManager(s3ImageIds: imagesToDownloadFromBlock)
        }
    }
    
    private func downloadImagesToFileManager(s3ImageIds: [(String, String)]) {
        for imageId in s3ImageIds {
            let currentImageSetList = self.fullImageSet.map {$0.imageName}
            //Additional check to make sure we're only download images we don't have
            if(!currentImageSetList.contains(imageId.1)) {
                Amplify.Storage.downloadData(key: imageId.1).resultPublisher
                    .receive(on: DispatchQueue.global())
                    .compactMap({UIImage(data: $0)})
                    .sink { _ in
                    } receiveValue: { [weak self] image in
                        guard let self = self else {
                            return
                        }
                        Log.info("completed download for image: \(imageId)")
                        self.fileManager.saveImage(image: image, imageName: imageId.0, folderName: self.folderName)
                        let newSenseyeImage = SenseyeImage(image: image, imageName: imageId.0)
                        self.fullImageSet.append(newSenseyeImage)
                        Log.info("current count \(self.fullImageSet.count) of \(self.allImageNames.count)")
                        if self.fullImageSet.count == self.allImageNames.count {
                            self.handleCompletedDownload()
                        } else {
                            self.handleUpdatedImageDownload(latestCount: self.fullImageSet.count)
                        }
                    }.store(in: &cancellables)
            }
        }
    }
    
    private func handleCompletedDownload() {
        self.fullImageSet = self.fullImageSet.reorder(by: allImageNames)
        if self.allDownloadsFinished {
            Log.info("All downloads finished")
            DispatchQueue.main.async {
                self.finishedDownloadingAllImages = true
            }
        }
    }
    
    private func handleUpdatedImageDownload(latestCount: Int) {
        DispatchQueue.main.async {
            self.currentDownloadCount = "\(latestCount) of \(self.allImageNames.count)"
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
