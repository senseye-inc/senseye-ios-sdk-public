//
//  ImageService.swift
//  
//
//  Created by Frank Oftring on 7/29/22.
//

import SwiftUI
import Combine
import Amplify
import Alamofire

class ImageService: ObservableObject {
    private var authenticationService: AuthenticationService?
    private let baseURLString: String = "https://download.senseye.co/app/"
    
    init(authenticationService: AuthenticationService) {
        self.authenticationService = authenticationService
        addSubscribers()
    }
    
    @Published var imagesForBlock: [SenseyeImage] = []
    @Published var finishedDownloadingAllImages = false
    @Published var currentDownloadCount: String  = ""
    @Published var imageError: AlertItem? = nil
    
    private let fileManager = LocalFileManager()
    private var cancellables = Set<AnyCancellable>()
    private var startedInitialDownload = false
    private var fullImageSet: [SenseyeImage] = []
    private var allImageNames: [String] = []
    
    var senseyeImageSets: [SenseyeImageSet] = []
    
    var allDownloadsFinished: Bool {
        fullImageSet.count >= allImageNames.count
    }
    
    private func addSubscribers() {
        guard let authenticationService = self.authenticationService else { return }
        
        authenticationService.$isSignedIn
            .debounce(for: .milliseconds(10), scheduler: RunLoop.main)
            .receive(on: DispatchQueue.global(qos: .utility))
            .sink { [weak self] isSignedIn in
                guard let self = self else {return}
                if isSignedIn && !self.startedInitialDownload {
                    self.downloadImageSetConfigJSON()
                    self.startedInitialDownload = true
                }
            }
            .store(in: &cancellables)
    }
    
    private func downloadImageSetConfigJSON() {
        let jsonKey = "ptsd_image_sets/SenseyeImageSets.json"
        guard let requestURL = URL(string: baseURLString + jsonKey) else {
            Log.error("Error getting JSON URL")
            return
        }
        
        let jsonOperation = AF.request(requestURL).publishDecodable(type: [SenseyeImageSet].self).value()
        
        jsonOperation
            .sink(receiveCompletion: {
                if case let .failure(error) = $0 {
                    Log.error("Failed: \(error.localizedDescription).", userInfo: ["errorDescription": error.localizedDescription])
                    self.imageError = AlertContext.imageDownloadError
                }
                Log.info("JSON Completion: \($0)")
                self.getImages()
            }, receiveValue: { senseyeImageSets in
                self.senseyeImageSets = senseyeImageSets
                self.allImageNames = senseyeImageSets.flatMap({ $0.senseyeImages.compactMap({ $0.imageName}) })
            })
            .store(in: &cancellables)
    }
    
    private func getImages() {
        let allPreviouslyDownloadedSenseyeImages = fileManager.getImages(imageNames: allImageNames)
        let allPreviouslyDownloadedSenseyeImageNames = Set(allPreviouslyDownloadedSenseyeImages.map { $0.imageName })
        let fullImageNameSet = Set(allImageNames)
        
        self.fullImageSet = allPreviouslyDownloadedSenseyeImages
        let additionalImageNames = fullImageNameSet.subtracting(allPreviouslyDownloadedSenseyeImageNames)
        if (!additionalImageNames.isEmpty) {
            additionalImageNames.forEach({ self.downloadImageToFileManager(imageName: $0)})
            Log.info("Need to download images -> \(additionalImageNames)")
            Log.info("Additional Images Count: \(additionalImageNames.count)")
        } else {
            Log.info("All downloads finished previously")
            DispatchQueue.main.async {
                self.handleCompletedImageSetDownload()
            }
        }
    }
    
    private func downloadImageToFileManager(imageName: String) {
        guard let imageSet = senseyeImageSets.first(where: { $0.imageIds.contains(imageName) }) else {
            Log.error("Error getting Image Set")
            return
        }
       
        let imageLocation = imageSet.imageDownloadLocation + imageName + ".png"
        
        guard let requestURL = URL(string: baseURLString + imageLocation) else {
            Log.error("Erorr getting Image location for image: \(imageName)")
            return
        }

        let downloadImageTask = AF.download(requestURL).publishData(queue: .global(qos: .userInitiated)).value()
        
        downloadImageTask
            .compactMap({ UIImage(data: $0) })
            .sink {
                if case let .failure(error) = $0 {
                    Log.error("Failed: \(error.localizedDescription).", userInfo: ["imageSetError": imageLocation,
                                                                                   "errorDescription": error.localizedDescription])
                    DispatchQueue.main.async {
                        self.imageError = AlertContext.imageDownloadError
                    }
                }
            } receiveValue: { [weak self] image in
                guard let self = self else { return }
                Log.info("completed download for image: \(imageName)")
                let downsizedImage = image.scaleForDevicePreservingAspectRatio()
                let imageURL = self.fileManager.saveImage(image: downsizedImage, imageName: imageName)
                let newSenseyeImage = SenseyeImage(imageUrl: imageURL, imageName: imageName)
                self.fullImageSet.append(newSenseyeImage)
                Log.info("current count \(self.fullImageSet.count) of \(self.allImageNames.count)")
                if self.fullImageSet.count == self.allImageNames.count {
                    self.handleCompletedImageSetDownload()
                } else {
                    self.handleUpdatedImageDownload(latestCount: self.fullImageSet.count)
                }
            }.store(in: &cancellables)
    }
    
    func checkForImages(at blockNumber: Int) {
        guard let currentImageSet = senseyeImageSets.first(where: { $0.blockNumber == blockNumber }) else { return }
        let imageSetIDs = currentImageSet.senseyeImages.map({ $0.imageName })
        updateImagesForBlock(imageSetIds: imageSetIDs)
    }

    private func updateImagesForBlock(imageSetIds: [String]) {
        self.imagesForBlock = fullImageSet.filter { imageSetIds.contains($0.imageName) }
    }
    
    private func handleCompletedImageSetDownload() {
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

    func getCategory(of imageId: String) -> AffectiveImageCategory? {
        return senseyeImageSets.first { (SenseyeImageSet) in
            SenseyeImageSet.imageIds.contains(imageId)
        }?.category
    }
}

struct SenseyeImageSet: Codable {
    let blockNumber: Int
    let imageIds: [String]
    let category: AffectiveImageCategory?
    let tabType: String?
    
    var senseyeImages: [SenseyeImage] {
        imageIds.map({ SenseyeImage(imageUrl: imageDownloadLocation + $0, imageName: $0)})
    }
    
    var imageDownloadLocation: String {
        guard let tabType = TabType(rawValue: self.tabType ?? "") else { return "" }
        switch tabType {
        case .affectiveImageView:
            return "ptsd_image_sets/block_\(String(describing: blockNumber))/"
        case .attentionBiasFaceView:
            return "attention_bias_faces/"
        default:
            return ""
        }
    }
    
    init(blockNumber: Int, imageIds: [String], category: AffectiveImageCategory? = nil, tabType: TabType? = nil) {
        self.imageIds = imageIds
        self.blockNumber = blockNumber
        self.category = category
        self.tabType = tabType?.rawValue
    }
}

enum AffectiveImageCategory: String, CaseIterable, Codable {
    case positive
    case neutral
    case negative
    case negativeArousal
    case facialExpression
}

// MARK: - Attention Bias Face Task
struct SenseyeFaceSet: Codable {
    let faces: [String]
    let dotLocation: DotLocation
}

enum DotLocation: Codable {
    case top, bottom
}
