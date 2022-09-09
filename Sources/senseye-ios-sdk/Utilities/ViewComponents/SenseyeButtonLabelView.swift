//
//  SenseyeButton.swift
//
//  Created by Frank Oftring on 4/12/22.
//

import SwiftUI

@available(iOS 13.0, *)
struct SenseyeButton: View {
    
    let text: String
    let foregroundColor: Color
    let fillColor: Color
    
    var body: some View {
        Text(text.uppercased())
            .foregroundColor(foregroundColor)
            .padding()
            .frame(minWidth: 147, minHeight: 52)
            .background(
                RoundedRectangle(
                    cornerRadius: 34,
                    style: .continuous
                )
                .fill(fillColor)
            )
    }
}
