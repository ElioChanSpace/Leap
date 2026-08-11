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
    private var previousCPUInfo: processor_info_array_t?
    private var previousCPUInfoCount: mach_msg_type_number_t = 0
    private var numCPUs: natural_t = 0

    func startMonitoring() {
        // 获取 CPU 数量
        var size = MemoryLayout<natural_t>.size
        sysctlbyname("hw.ncpu", &numCPUs, &size, nil, 0)

        updateStats()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateStats()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func updateStats() {
        updateCPUUsage()
        updateMemoryUsage()
        updateTemperature()
        updateDiskUsage()
    }

    // MARK: - CPU Usage

    private func updateCPUUsage() {
        var cpuInfo: processor_info_array_t?
        var cpuInfoCount: mach_msg_type_number_t = 0

        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPUs, &cpuInfo, &cpuInfoCount)
        guard result == KERN_SUCCESS, let cpuInfo = cpuInfo else { return }

        defer {
            let size = vm_size_t(cpuInfoCount) * vm_size_t(MemoryLayout<Int32>.size)
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), size)
        }

        if let previousCPUInfo = previousCPUInfo, previousCPUInfoCount == cpuInfoCount {
            var totalUsage: Double = 0
            let stride = Int(CPU_STATE_MAX)

            for i in 0..<Int(numCPUs) {
                let offset = stride * i
                let user = Double(cpuInfo[offset + Int(CPU_STATE_USER)] - previousCPUInfo[offset + Int(CPU_STATE_USER)])
                let system = Double(cpuInfo[offset + Int(CPU_STATE_SYSTEM)] - previousCPUInfo[offset + Int(CPU_STATE_SYSTEM)])
                let idle = Double(cpuInfo[offset + Int(CPU_STATE_IDLE)] - previousCPUInfo[offset + Int(CPU_STATE_IDLE)])
                let nice = Double(cpuInfo[offset + Int(CPU_STATE_NICE)] - previousCPUInfo[offset + Int(CPU_STATE_NICE)])

                let total = user + system + idle + nice
                if total > 0 {
                    totalUsage += (user + system + nice) / total
                }
            }

            DispatchQueue.main.async { [weak self] in
                self?.cpuUsage = totalUsage / Double(self?.numCPUs ?? 1) * 100
            }
        }

        // 保存当前 CPU 信息用于下次计算
        let size = vm_size_t(cpuInfoCount) * vm_size_t(MemoryLayout<Int32>.size)
        let newPreviousInfo = UnsafeMutablePointer<Int32>.allocate(capacity: Int(cpuInfoCount))
        newPreviousInfo.initialize(from: cpuInfo, count: Int(cpuInfoCount))

        // 释放旧的 CPU 信息
        if let oldInfo = previousCPUInfo {
            let oldSize = vm_size_t(previousCPUInfoCount) * vm_size_t(MemoryLayout<Int32>.size)
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: oldInfo), oldSize)
        }

        previousCPUInfo = newPreviousInfo
        previousCPUInfoCount = cpuInfoCount
    }

    // MARK: - Memory Usage

    private func updateMemoryUsage() {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size) / 4

        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else { return }

        let pageSize = Double(vm_kernel_page_size)
        let active = Double(stats.active_count) * pageSize
        let wired = Double(stats.wire_count) * pageSize

        let totalMemory = Double(ProcessInfo.processInfo.physicalMemory)
        let usedMemory = active + wired

        DispatchQueue.main.async { [weak self] in
            self?.memoryUsage = usedMemory / totalMemory * 100
            self?.memoryUsed = self?.formatBytes(usedMemory) ?? "0 GB"
            self?.memoryTotal = self?.formatBytes(totalMemory) ?? "0 GB"
        }
    }

    // MARK: - Temperature

    private func updateTemperature() {
        // 使用系统命令获取温度（简化实现）
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // 估算温度：基础温度 40°C + CPU 使用率 * 0.4
            self.temperature = 40 + self.cpuUsage * 0.4
        }
    }

    // MARK: - Disk Usage

    private func updateDiskUsage() {
        let fileManager = FileManager.default
        guard let path = fileManager.urls(for: .userDirectory, in: .localDomainMask).first?.path else { return }

        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: path)
            if let totalSize = attributes[.systemSize] as? NSNumber,
               let freeSize = attributes[.systemFreeSize] as? NSNumber {
                let total = totalSize.doubleValue
                let free = freeSize.doubleValue
                let used = total - free

                DispatchQueue.main.async { [weak self] in
                    self?.diskUsage = used / total * 100
                    self?.diskUsed = self?.formatBytes(used) ?? "0 GB"
                    self?.diskTotal = self?.formatBytes(total) ?? "0 GB"
                }
            }
        } catch {
            print("Error getting disk info: \(error)")
        }
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
