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
    
    var body: some View {
        Spacer()
        Label(currentComplianceLabel, systemImage: currentComplianceIcon)
    }
    
}
