//
//  ButtonViews.swift
//  Example_iOS
//
//  Created by Enrico Zannini on 15/10/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import SwiftUI

public extension Color {
    static let tealBlue = Color(red: 0.0, green: 0.49, blue: 0.76)
}

struct TealiumButtonModifier: ViewModifier {
    @Environment(\.isEnabled) var isEnabled
    func body(content: Content) -> some View {
        content.frame(maxWidth: maxWidth)
            .padding()
            .background(isEnabled ? Color.tealBlue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(10)
            .shadow(radius: 8)
    }

    var maxWidth: Double {
        #if os(tvOS)
        400.0
        #else
        200.0
        #endif
    }
}

struct TealiumButtonStyle: ButtonStyle {
    #if os(tvOS)
    @Environment(\.isFocused) private var isFocused: Bool
    #endif

    func makeBody(configuration: Configuration) -> some View {
        configuration.label.tealiumButtonUI()
            .opacity(configuration.isPressed ? 0.5 : 1.0)
            #if os(tvOS)
            .shadow(color: isFocused ? .black.opacity(0.9) : .clear, radius: 16, x: 0, y: 5)
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isFocused)
            #endif
    }
}

public extension View {

    func tealiumButtonUI() -> some View {
        self.modifier(TealiumButtonModifier())
    }
}

