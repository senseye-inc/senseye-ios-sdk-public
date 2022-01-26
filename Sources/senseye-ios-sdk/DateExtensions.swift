//
//  File.swift
//  
//
//  Created by Deepak Kumar on 1/25/22.
//

import Foundation

extension Date {
    func currentTimeMillis() -> Int64 {
        return Int64(self.timeIntervalSince1970 * 1000)
    }
}
