//
//  TealiumError.swift
//  tealium-swift-Core-iOS
//
//  Created by Den Guzov on 29/11/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

public enum TealiumError: Error, TealiumErrorEnum {
    case moduleNotEnabled, initializationError(Error?), genericError(String?)
}
