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
    /// - Returns: `[String: Int64]` containing current device memory usage info, in whole megabytes
    var memoryUsage: [String: Int64] {
        let pageSize = vm_kernel_page_size
        let machHost = mach_host_self()
        var size = HOST_VM_INFO64_COUNT
        let hostInfo = vm_statistics64_t.allocate(capacity: 1)

        _ = hostInfo.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
            host_statistics64(machHost, HOST_VM_INFO64, $0, &size)
        }

        let data = hostInfo.move()
        hostInfo.deallocate()

        let physical = Int64(ProcessInfo.processInfo.physicalMemory) / ByteUnit.megabyte
        let free = Int64(data.free_count) * Int64(pageSize) / ByteUnit.megabyte
        let active = Int64(data.active_count) * Int64(pageSize) / ByteUnit.megabyte
        let inactive = Int64(data.inactive_count) * Int64(pageSize) / ByteUnit.megabyte
        let wired = Int64(data.wire_count) * Int64(pageSize) / ByteUnit.megabyte
        // Result of the compression. This is what you see in Activity Monitor
        let compressed = Int64(data.compressor_page_count) * Int64(pageSize) / ByteUnit.megabyte

        return [
            DeviceDataKey.memoryActive: active,
            DeviceDataKey.memoryCompressed: compressed,
            DeviceDataKey.memoryFree: free,
            DeviceDataKey.memoryInactive: inactive,
            DeviceDataKey.memoryWired: wired,
            DeviceDataKey.physicalMemory: physical,
        ]
    }
}
