//
//  DeviceDataProvider.swift
//  tealium-prism
//
//  Created by Den Guzov on 13/05/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

typealias OrientationProvider = () -> DataObject

class DeviceDataProvider {
    let orientationProvider: OrientationProvider

    init(orientationProvider: @escaping OrientationProvider = defaultOrientationProvider) {
        self.orientationProvider = orientationProvider
    }

    /// - Returns: `String` containing the device's CPU architecture
    var architecture: String {
        let bit = MemoryLayout<Int>.size
        if bit == MemoryLayout<Int64>.size {
            return "64"
        }
        return "32"
    }

    /// - Returns: `String` containing current CPU type
    var cpuType: String {
        var type = cpu_type_t()
        var cpuSize = MemoryLayout<cpu_type_t>.size
        sysctlbyname("hw.cputype", &type, &cpuSize, nil, 0)

        var subType = cpu_subtype_t()
        var subTypeSize = MemoryLayout<cpu_subtype_t>.size
        sysctlbyname("hw.cpusubtype", &subType, &subTypeSize, nil, 0)

        if type == CPU_TYPE_ARM64 {
            return switch subType {
            case CPU_SUBTYPE_ARM64E:
                "ARM64e"
            case CPU_SUBTYPE_ARM64_V8:
                "ARM64v8"
            default:
                "ARM64"
            }
        } else if type == CPU_TYPE_ARM {
            return switch subType {
            case CPU_SUBTYPE_ARM_V8:
                "ARMV8"
            case CPU_SUBTYPE_ARM_V7:
                "ARMV7"
            case CPU_SUBTYPE_ARM_V7EM:
                "ARMV7em"
            case CPU_SUBTYPE_ARM_V7F:
                "ARMV7f"
            case CPU_SUBTYPE_ARM_V7K:
                "ARMV7k"
            case CPU_SUBTYPE_ARM_V7M:
                "ARMV7m"
            case CPU_SUBTYPE_ARM_V7S:
                "ARMV7s"
            default:
                "ARM"
            }
        } else if type == CPU_TYPE_ARM64_32 {
            return switch subType {
            case CPU_SUBTYPE_ARM64_32_V8:
                "ARM64_32v8"
            default:
                "ARM64_32"
            }
        } else if type == CPU_TYPE_X86_64 {
            return "x86_64"
        } else {
            return TealiumConstants.unknown
        }
    }

    /// - Returns: `String` containing Apple model name
    static var basicModel: String {
        #if os(OSX)
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)

        var modelIdentifier: [CChar] = Array(repeating: 0, count: size)
        sysctlbyname("hw.model", &modelIdentifier, &size, nil, 0)

        return String(cString: modelIdentifier)
        #else
        if ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] != nil {
            return "x86_64"
        }
        var sysinfo = utsname()
        uname(&sysinfo) // ignore return value
        guard let model = String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii) else {
            return ""
        }
        return model.trimmingCharacters(in: .controlCharacters)
        #endif
    }

    /**
     * Retrieves the full consumer device name, e.g. iPhone SE, and model variant info
     * from the structure shown below (as a JSON example).
     *
     * - Returns: `[String: String]` of model information
     *
     * JSON example of the structure:
     * ```json
     * {
     *      "iPhone7,1": {
     *          "device_model": "iPhone 6 Plus",
     *          "model_variant": "5G"
     *      }
     * }
     * ```
     */
    func getModelInfo(from extractor: DataItemExtractor, model: String = basicModel) -> DataObject? {
        guard let modelInfo = extractor.getDataDictionary(key: model),
              let deviceModel = modelInfo.get(key: DeviceDataKey.deviceModel, as: String.self),
              let modelVariant = modelInfo.get(key: DeviceDataKey.modelVariant, as: String.self) else {
            return nil
        }
        return [
            DeviceDataKey.deviceType: model,
            DeviceDataKey.deviceModel: deviceModel,
            DeviceDataKey.device: deviceModel,
            DeviceDataKey.modelVariant: modelVariant
        ]
    }

    var deviceOrigin: String {
        #if os(iOS)
        return "mobile"
        #elseif os(tvOS)
        return "tv"
        #elseif os(watchOS)
        return "watch"
        #elseif os(OSX)
        return "desktop"
        #else
        return TealiumConstants.unknown
        #endif
    }

    let manufacturer = "Apple"

    /// - Returns: `String` of  main locale of the device
    var language: String {
        return Locale.preferredLanguages[0]
    }
}

extension DeviceDataProvider {
    /// Data that only needs to be retrieved once for the lifetime of the host app.
    func getConstantData() -> [String: DataInput] {
        var result = [String: DataInput]()
        result[DeviceDataKey.architecture] = architecture
        result[DeviceDataKey.cpuType] = cpuType
        result[DeviceDataKey.deviceOrigin] = deviceOrigin
        result[DeviceDataKey.manufacturer] = manufacturer
        result[DeviceDataKey.osBuild] = osBuild
        result[DeviceDataKey.osName] = osName
        result[DeviceDataKey.osVersion] = osVersion
        result[DeviceDataKey.platform] = osName.lowercased()
        return result
    }
}
