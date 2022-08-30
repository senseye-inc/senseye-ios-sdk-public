//
//  DoubleExtensions.swift
//  
//
//  Created by Frank Oftring on 8/26/22.
//

import Foundation

extension Double {
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
