//
//  SenseyePicker.swift
//  
//
//  Created by Frank Oftring on 7/1/22.
//

import Foundation
import SwiftUI

struct SenseyePicker: View {
    let title: String
    let currentValue: String?
    var body: some View {
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading, spacing: 20) {
                Text(title)
                    .foregroundColor(.senseyeSecondary)
                    .bold()
                Text(currentValue ?? "N/A")
                    .foregroundColor(.senseyeTextColor)
            }
            Spacer()
            Image(systemName: "chevron.down")
                .pickerStyle(.menu)
                .accentColor(.senseyeTextColor)
        }
        .padding()
    }
}
