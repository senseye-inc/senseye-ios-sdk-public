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

    var numberOfImagesShown = 0
    var totalNumberOfImagesToBeShown = 24
    var finishedAllTasks: Bool = false
    var timerCount: Int = 0
    var currentImageName: String {
        imageNames[currentImageIndex]
    }

    @Published var currentImageIndex: Int = 0

    func showImages(didFinishCompletion: @escaping () -> Void) {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [self] timer in
            timerCount += 1
            numberOfImagesShown += 1
            if timerCount < imageNames.count {
                currentImageIndex += 1 
            } else {
                timer.invalidate()
                print("Image View Timer Cancelled")
                if numberOfImagesShown >= totalNumberOfImagesToBeShown {
                    finishedAllTasks = true
                    print("Finsished all tasks")
                }
                reset()
                didFinishCompletion()
            }
        }
    }

    private func reset() {
        print("Reset Called")
        currentImageIndex = 0
        timerCount = 0
    }
}


