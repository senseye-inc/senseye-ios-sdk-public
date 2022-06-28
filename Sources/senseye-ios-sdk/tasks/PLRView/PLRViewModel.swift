//
//  PLRViewModel.swift
//
//  Created by Frank Oftring on 5/25/22.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
class PLRViewModel: ObservableObject {

    @Published var backgroundColor: Color = .white
    @Published var xMarkColor: Color = .black
    @Published var shouldShowConfirmationView: Bool = false

    var currentInterval: Int = 0
    var numberOfPLRShown: Int = 1

    func showPLR(didFinishCompletion: @escaping () -> Void) {
        numberOfPLRShown += 1
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [self] timer in
            currentInterval += 1
            if currentInterval <= 10 {
                DispatchQueue.main.async {
                    self.toggleColors()
                }
            } else {
                timer.invalidate()
                Log.info("PLRView Timer Cancelled")
                didFinishCompletion()
                reset()
            }
        }
    }

    private func toggleColors() {
        backgroundColor = (backgroundColor == .white ? .black : .white)
        xMarkColor = (xMarkColor == .black ? .white : .black)
    }

    private func reset() {
        currentInterval = 0
    }
}
