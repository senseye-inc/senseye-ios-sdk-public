//
//  File.swift
//  
//
//  Created by Frank Oftring on 9/27/22.
//

import SwiftUI
@available(iOS 13.0, *)
struct DisableScrolling: ViewModifier {
    var disabled: Bool
    
    func body(content: Content) -> some View {
        if disabled {
            content
                .simultaneousGesture(DragGesture(minimumDistance: 0))
        } else {
            content
        }
    }
}
@available(iOS 13.0, *)
extension View {
    func disableScrolling(disabled: Bool) -> some View {
        modifier(DisableScrolling(disabled: disabled))
    }
}
