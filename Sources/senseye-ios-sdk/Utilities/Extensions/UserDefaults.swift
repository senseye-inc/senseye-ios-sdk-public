//
//  UserDefaults.swift
//  
//
//  Created by Frank Oftring on 10/6/22.
//

import Foundation

enum AppStorageKeys: String, CaseIterable {
    case cameraType
    case username

    func callAsFunction() -> String {
        return self.rawValue
    }
}

extension UserDefaults {
    func resetUser() {
        AppStorageKeys.allCases.forEach {
            Log.info("Removing user default: \($0())")
            self.removeObject(forKey: $0())
        }
    }
}
