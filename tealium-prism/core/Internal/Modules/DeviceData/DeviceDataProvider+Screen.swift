//
//  DeviceDataProvider+Screen.swift
//  tealium-prism
//
//  Created by Den Guzov on 21/05/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

#if os(OSX)
import Foundation
#else
import UIKit
#endif
#if os(watchOS)
import WatchKit
#endif

enum ExtendedOrientation {
    static let landscape: String = "Landscape"
    static let portrait: String = "Portrait"
    static let portraitUpsideDown: String = "Portrait Upside Down"
    static let landscapeLeft: String = "Landscape Left"
    static let landscapeRight: String = "Landscape Right"
}

#if os(iOS)
fileprivate extension UIInterfaceOrientation {
    func toExtendedOrientation() -> String {
        return switch self {
        case .landscapeLeft:
            ExtendedOrientation.landscapeLeft
        case .landscapeRight:
            ExtendedOrientation.landscapeRight
        case .portrait:
            ExtendedOrientation.portrait
        case .portraitUpsideDown:
            ExtendedOrientation.portraitUpsideDown
        case .unknown:
            TealiumConstants.unknown
        @unknown default:
            TealiumConstants.unknown
        }
    }
}
#endif

extension DeviceDataProvider {
    static func defaultOrientationProvider() -> DataObject {
        let unknownOrientation: DataObject = [
            DeviceDataKey.orientation: TealiumConstants.unknown,
            DeviceDataKey.extendedOrientation: TealiumConstants.unknown
        ]
        #if os(iOS)
        let orientation: UIInterfaceOrientation
        if #available(iOS 13.0, *) {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                return unknownOrientation
            }
            orientation = windowScene.interfaceOrientation
        } else {
            orientation = UIApplication.shared.statusBarOrientation
        }
        let isLandscape = orientation.isLandscape == true
        let fullOrientation: DataObject = [
            DeviceDataKey.orientation: isLandscape ? ExtendedOrientation.landscape : ExtendedOrientation.portrait,
            DeviceDataKey.extendedOrientation: orientation.toExtendedOrientation()
        ]
        return fullOrientation
        #else
        return unknownOrientation
        #endif
    }

    // MARK: Resolution
    /// - Returns: `String` containing the device's resolution
    var resolution: String {
        #if os(OSX)
        return TealiumConstants.unknown
        #elseif os(watchOS)
        let res = WKInterfaceDevice.current().screenBounds
        let scale = WKInterfaceDevice.current().screenScale
        let width = res.width * scale
        let height = res.height * scale
        let stringRes = String(format: "%.0fx%.0f", width, height)
        return stringRes
        #else
        let res = UIScreen.main.bounds
        let scale = UIScreen.main.scale
        let width = res.width * scale
        let height = res.height * scale
        let stringRes = String(format: "%.0fx%.0f", width, height)
        return stringRes
        #endif
    }

    var logicalResolution: String {
        #if os(OSX)
        return TealiumConstants.unknown
        #elseif os(watchOS)
        let res = WKInterfaceDevice.current().screenBounds
        let stringRes = String(format: "%.0fx%.0f", res.width, res.height)
        return stringRes
        #else
        let res = UIScreen.main.bounds
        let stringRes = String(format: "%.0fx%.0f", res.width, res.height)
        return stringRes
        #endif
    }

    // MARK: Orientation
    func getScreenOrientation(completion: @escaping (DataObject) -> Void) {
        TealiumQueue.main.ensureOnQueue {
            completion(self.orientationProvider())
        }
    }

    /// - Returns: `String` containing the device's UI orientation
    #if os(iOS)
    private func _getExtendedOrientation(_ orientation: UIInterfaceOrientation?) -> String {
        return switch orientation {
        case .landscapeLeft:
            ExtendedOrientation.landscapeLeft
        case .landscapeRight:
            ExtendedOrientation.landscapeRight
        case .portrait:
            ExtendedOrientation.portrait
        case .portraitUpsideDown:
            ExtendedOrientation.portraitUpsideDown
        case .unknown, nil:
            TealiumConstants.unknown
        @unknown default:
            TealiumConstants.unknown
        }
    }
    #endif
}
