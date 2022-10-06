//
//  UserDefaults.swift
//  
//
//  Created by Frank Oftring on 10/6/22.
//

import Foundation
extension UserDefaults {
    func resetUser() {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
    }
}
