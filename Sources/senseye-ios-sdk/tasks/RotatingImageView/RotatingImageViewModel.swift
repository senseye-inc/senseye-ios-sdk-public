//
//  ImageViewModel.swift
//
//
//  Created by Frank Oftring on 5/23/22.
//

import Foundation
import Combine
import SwiftUI

@available(iOS 13.0, *)
class RotatingImageViewModel: ObservableObject {

    let imageNames: [String] = ["acorns_1", "astronaut_1", "bird_3", "beach", "bird_1", "bricks_1", "building_1", "cake3", "icecream", "lake_13", "leaves_1", "nature_1"]

    @Published var shouldShowConfirmationView: Bool = false
    @Published var currentImageIndex: Int = 0

    var numberOfImagesShown = 0
    var totalNumberOfImagesToBeShown = 24
    var numberOfImageSetsShown: Int = 1

    var finishedAllTasks: Bool {
        numberOfImagesShown >= totalNumberOfImagesToBeShown
    }
    var currentImageName: String {
        imageNames[currentImageIndex]
    }

    var taskCompleted: String {
        "PTSD \(numberOfImagesShown)/\(totalNumberOfImagesToBeShown)"
    }

    func showImages(didFinishCompletion: @escaping () -> Void) {
        numberOfImageSetsShown += 1
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [self] timer in
            numberOfImagesShown += 1
            if currentImageIndex < imageNames.count - 1 {
                currentImageIndex += 1
            } else {
                timer.invalidate()
                Log.info("RotatingImageViewModel Timer Cancelled")
                reset()
                didFinishCompletion()
            }
        }
    }

    func removeLastImageSet() {
        self.numberOfImagesShown -= (self.imageNames.count)
    }

    private func reset() {
        currentImageIndex = 0
    }
}


