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
    @Published var currentInterval: Int = 0

    func showPLR(didFinishCompletion: @escaping () -> Void) {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            self.currentInterval += 1
            if (self.currentInterval <= 10) {
                DispatchQueue.main.async {
                    self.switchColors()
                }
            } else {
                timer.invalidate()
                print("PLR Time Cancelled")
                didFinishCompletion()
                self.reset()
            }
        }
    }

    private func switchColors() {
        backgroundColor = (backgroundColor == .white ? .black : .white)
        xMarkColor = (xMarkColor == .black ? .white : .black)
    }

    private func reset() {
        currentInterval = 0
    }
}
