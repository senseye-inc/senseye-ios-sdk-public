//
//  SwiftUIView.swift
//  
//
//  Created by Deepak Kumar on 9/27/22.
//

import SwiftUI

struct FacialComplianceLabelView: View {
    
    @Binding var currentComplianceInfo: FacialComplianceStatus
    
    var body: some View {
        Spacer()
        Label(currentComplianceInfo.statusMessage, systemImage: currentComplianceInfo.statusIcon)
            .font(.headline)
            .padding()
            .background(.gray.opacity(0.5))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(currentComplianceInfo.statusBackgroundColor, lineWidth: 4)
            )
    }
    
}
