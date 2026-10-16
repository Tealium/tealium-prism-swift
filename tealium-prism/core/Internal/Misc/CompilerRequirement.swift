//
//  CompilerRequirement.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 21/09/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

#if compiler(<6.0)
#error("Tealium Prism requires the Swift 6.0 compiler (Xcode 16 or later).")
#endif
