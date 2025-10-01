//
//  String+Deserialize.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 19/09/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

extension String {
    func deserialize() throws -> Any {
        let anyCodable: AnyCodable = try deserializeCodable()
        return anyCodable.value
    }

    func deserializeCodable<T: Codable>() throws -> T {
        let data = Data(self.utf8)
        let decoder = Tealium.jsonDecoder
        let response = try decoder.decode(T.self, from: data)
        return response
    }
}
