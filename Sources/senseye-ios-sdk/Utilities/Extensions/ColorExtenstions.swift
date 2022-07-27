//
//  File.swift
//  
//
//  Created by Frank Oftring on 4/11/22.
//

import SwiftUI

@available(iOS 14.0, *)
extension Color {
    static let senseyePrimary = Color("senseyePrimary")
    static let senseyeSecondary = Color("senseyeSecondary")
    static let senseyeRed = Color("senseyeRed")
    static let senseyeTextColor = Color("senseyeTextColor")


    func toHex() -> String? {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)

        if components.count >= 4 {
            a = Float(components[3])
        }

        if a != Float(1.0) {
            return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
}
