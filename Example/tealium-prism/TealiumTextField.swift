//
//  TealiumTextField.swift
//  Example_iOS
//
//  Created by Enrico Zannini on 15/10/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import SwiftUI

public struct TealiumTextField: View {
    @Binding var value: String
    var isSecure: Bool
    var imageName: String?
    var placeholder: String?
    let applyButtonText: String
    let onCommit: (() -> ())?
    @Environment(\.isEnabled) var isEnabled

    public init(_ value: Binding<String>,
                secure: Bool = false,
                imageName: String? = nil,
                placeholder: String? = nil,
                applyButtonText: String = "Apply",
                onCommit: (() -> ())? = nil) {
        self._value = value
        self.isSecure = secure
        self.imageName = imageName
        self.placeholder = placeholder
        self.applyButtonText = applyButtonText
        self.onCommit = onCommit
    }
    
    public var body: some View {
        let color = isEnabled ? Color.tealBlue : Color.gray
        HStack {
            if let imageName = imageName {
                Image(systemName: imageName)
                    .foregroundColor(color)
            }
            if isSecure {
                SecureField(placeholder ?? "", text: $value)
            } else {
                TextField(placeholder ?? "", text: $value)
                    .foregroundColor(color)
                    .accentColor(color)
                    .onSubmit {
                        onCommit?()
                    }
            }
          }
        .frame(maxWidth: maxWidth)
        .padding()
        .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(color, lineWidth: 1))
        if let onCommit = onCommit {
            Button(applyButtonText) {
                onCommit()
            }
        }
    }

    var maxWidth: Double {
        #if os(tvOS)
        400.0
        #else
        200.0
        #endif
    }
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
#Preview {
    @Previewable @State var text: String = ""
    Group {
        TealiumTextField($text, placeholder: "placeholder", applyButtonText: "Something", onCommit: {

        })
    }.buttonStyle(TealiumButtonStyle())
}
