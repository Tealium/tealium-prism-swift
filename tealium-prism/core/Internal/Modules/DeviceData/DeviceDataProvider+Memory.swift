//
//  DeviceDataProvider+Memory.swift
//  tealium-prism
//
//  Created by Den Guzov on 21/05/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Darwin
import Foundation

private let HOST_VM_INFO64_COUNT: mach_msg_type_number_t =
UInt32(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)

extension DeviceDataProvider {
    /// - Returns: `[String: String]` containing current device memory usage info
    var memoryUsage: [String: String] {
        let pageSize = vm_kernel_page_size
        let machHost = mach_host_self()
        var size = HOST_VM_INFO64_COUNT
        let hostInfo = vm_statistics64_t.allocate(capacity: 1)

        _ = hostInfo.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
            host_statistics64(machHost, HOST_VM_INFO64, $0, &size)
        }

        let data = hostInfo.move()
        hostInfo.deallocate()

        let physical = Double(ProcessInfo.processInfo.physicalMemory) / ByteUnit.megabyte
        let free = Double(data.free_count) * Double(pageSize) / ByteUnit.megabyte
        let active = Double(data.active_count) * Double(pageSize) / ByteUnit.megabyte
        let inactive = Double(data.inactive_count) * Double(pageSize) / ByteUnit.megabyte
        let wired = Double(data.wire_count) * Double(pageSize) / ByteUnit.megabyte
        // Result of the compression. This is what you see in Activity Monitor
        let compressed = Double(data.compressor_page_count) * Double(pageSize) / ByteUnit.megabyte

        return [
            DeviceDataKey.memoryActive: String(format: "%0.2fMB", active),
            DeviceDataKey.memoryCompressed: String(format: "%0.2fMB", compressed),
            DeviceDataKey.memoryFree: String(format: "%0.2fMB", free),
            DeviceDataKey.memoryInactive: String(format: "%0.2fMB", inactive),
            DeviceDataKey.memoryWired: String(format: "%0.2fMB", wired),
            DeviceDataKey.physicalMemory: String(format: "%0.2fMB", physical),
        ]
    }
}
