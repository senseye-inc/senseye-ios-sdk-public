//
//  SwiftUIView.swift
//  
//
//  Created by Frank Oftring on 4/6/22.
//

import SwiftUI

@available(iOS 14.0, *)
struct ResultsView: View {
       
    @StateObject var resultsViewModel: ResultsViewModel

    init(resultsViewModel: ResultsViewModel) {
        _resultsViewModel = StateObject(wrappedValue: resultsViewModel)
    }
    
    var body: some View {
        VStack {
            Text("Hello from results view")
            Text("Status: \(resultsViewModel.predictionResult?.resultStatus ?? "Error no predictionResult")")
        }
    }
}

//struct SwiftUIView_Previews: PreviewProvider {
//    @available(iOS 13.0.0, *)
//    static var previews: some View {
//        if #available(iOS 14.0, *) {
//            ResultsView(currentPathTitle: .constant("Example Text"))
//        } else {
//            // Fallback on earlier versions
//        }
//    }
//}
