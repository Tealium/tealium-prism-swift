//
//  String+Converter.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 10/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

extension String {
    struct Converter: DataItemConverter {
        typealias Convertible = String
        func convert(dataItem: DataItem) -> Convertible? {
            dataItem.get()
        }
    }
    static let converter: any DataItemConverter<String> = Converter()
}
