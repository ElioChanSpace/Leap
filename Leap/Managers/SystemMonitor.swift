import Foundation
import Combine
import AppKit

class SystemMonitor: ObservableObject {
    @Published var cpuUsage: Double = 0
    @Published var memoryUsage: Double = 0
    @Published var memoryUsed: String = "0 GB"
    @Published var memoryTotal: String = "0 GB"
    @Published var temperature: Double = 0
    @Published var diskUsage: Double = 0
    @Published var diskUsed: String = "0 GB"
    @Published var diskTotal: String = "0 GB"

    private var timer: Timer?

    func startMonitoring() {
        updateStats()
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.updateStats()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func updateStats() {
        // 在后台线程更新数据
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let cpu = self?.getCPUUsage() ?? 0
            let (memUsage, memUsed, memTotal) = self?.getMemoryUsage() ?? (0, "0 GB", "0 GB")
            let disk = self?.getDiskUsage() ?? (0, "0 GB", "0 GB")

            DispatchQueue.main.async {
                self?.cpuUsage = cpu
                self?.memoryUsage = memUsage
                self?.memoryUsed = memUsed
                self?.memoryTotal = memTotal
                self?.diskUsage = disk.0
                self?.diskUsed = disk.1
                self?.diskTotal = disk.2
                self?.temperature = 40 + cpu * 0.4
            }
        }
    }

    // MARK: - CPU Usage

    private func getCPUUsage() -> Double {
        var numCPUs: natural_t = 0
        var cpuInfo: processor_info_array_t?
        var cpuInfoCount: mach_msg_type_number_t = 0

        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPUs, &cpuInfo, &cpuInfoCount)
        guard result == KERN_SUCCESS, let cpuInfo = cpuInfo else { return 0 }

        defer {
            let size = vm_size_t(cpuInfoCount) * vm_size_t(MemoryLayout<Int32>.size)
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), size)
        }

        var totalUsage: Double = 0
        let stride = Int(CPU_STATE_MAX)

        for i in 0..<Int(numCPUs) {
            let offset = stride * i
            let user = Double(cpuInfo[offset + Int(CPU_STATE_USER)])
            let system = Double(cpuInfo[offset + Int(CPU_STATE_SYSTEM)])
            let idle = Double(cpuInfo[offset + Int(CPU_STATE_IDLE)])
            let nice = Double(cpuInfo[offset + Int(CPU_STATE_NICE)])

            let total = user + system + idle + nice
            if total > 0 {
                totalUsage += (user + system + nice) / total
            }
        }

        return totalUsage / Double(numCPUs) * 100
    }

    // MARK: - Memory Usage

    private func getMemoryUsage() -> (Double, String, String) {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size) / 4

        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else { return (0, "0 GB", "0 GB") }

        let pageSize = Double(vm_kernel_page_size)
        let active = Double(stats.active_count) * pageSize
        let wired = Double(stats.wire_count) * pageSize

        let totalMemory = Double(ProcessInfo.processInfo.physicalMemory)
        let usedMemory = active + wired

        let usage = usedMemory / totalMemory * 100
        return (usage, formatBytes(usedMemory), formatBytes(totalMemory))
    }

    // MARK: - Disk Usage

    private func getDiskUsage() -> (Double, String, String) {
        let fileManager = FileManager.default
        guard let path = fileManager.urls(for: .userDirectory, in: .localDomainMask).first?.path else {
            return (0, "0 GB", "0 GB")
        }

        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: path)
            if let totalSize = attributes[.systemSize] as? NSNumber,
               let freeSize = attributes[.systemFreeSize] as? NSNumber {
                let total = totalSize.doubleValue
                let free = freeSize.doubleValue
                let used = total - free

                let usage = used / total * 100
                return (usage, formatBytes(used), formatBytes(total))
            }
        } catch {
            print("Error getting disk info: \(error)")
        }

        return (0, "0 GB", "0 GB")
    }

    // MARK: - Helpers

    private func formatBytes(_ bytes: Double) -> String {
        let gb = bytes / 1_073_741_824
        if gb >= 1 {
            return String(format: "%.1f GB", gb)
        }
        let mb = bytes / 1_048_576
        return String(format: "%.0f MB", mb)
    }
}
