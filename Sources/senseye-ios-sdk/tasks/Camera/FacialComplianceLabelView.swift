//
//  SwiftUIView.swift
//  
//
//  Created by Deepak Kumar on 9/27/22.
//

import SwiftUI

struct FacialComplianceLabelView: View {
    
    @Binding var currentComplianceIcon: String
    @Binding var currentComplianceLabel: String
    @Binding var currentComplianceColor: Color
    
    var body: some View {
        Spacer()
        Label(currentComplianceLabel, systemImage: currentComplianceIcon)
            .font(.headline)
            .padding()
            .background(.gray.opacity(0.5))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(currentComplianceColor, lineWidth: 4)
            )
    }
    
}
