//
//  File.swift
//  
//
//  Created by Frank Oftring on 4/7/22.
//

import Foundation


struct PredictionResult {
    var resultStatus: String
}

@available(iOS 13.0, *)
class ResultsViewModel: ObservableObject {
    
    @Published var predictionResult: PredictionResult?
    
}
