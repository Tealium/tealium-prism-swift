//
//  TealiumError.swift
//  tealium-swift-Core-iOS
//
//  Created by Den Guzov on 29/11/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

public enum TealiumError: Error, TealiumErrorEnum {
    /**
     * An object of a specific class could not be found.
     *
     * This could happen when that class is a module that is disabled
     * or if the class was anyway deallocated before it could be used.
     */
    case objectNotFound(AnyClass)

    /// An error happened during `Tealium` initialization that prevented the correct initialization of the `Tealium` instance.
    case initializationError(Error)

    /// A generic error with a human readable description.
    case genericError(String)
}
