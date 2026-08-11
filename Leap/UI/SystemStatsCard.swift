import SwiftUI

struct SystemStatsCard: View {
    @ObservedObject var monitor: SystemMonitor

    var body: some View {
        VStack(spacing: 16) {
            // CPU 和内存
            HStack(spacing: 12) {
                StatItem(
                    icon: "cpu",
                    label: "CPU",
                    value: String(format: "%.0f%%", monitor.cpuUsage),
                    progress: monitor.cpuUsage / 100,
                    color: .blue
                )

                StatItem(
                    icon: "memorychip",
                    label: "内存",
                    value: String(format: "%.0f%%", monitor.memoryUsage),
                    progress: monitor.memoryUsage / 100,
                    color: .green
                )
            }

            // 温度和磁盘
            HStack(spacing: 12) {
                StatItem(
                    icon: "thermometer",
                    label: "温度",
                    value: String(format: "%.0f°C", monitor.temperature),
                    progress: min(monitor.temperature / 100, 1.0),
                    color: temperatureColor
                )

                StatItem(
                    icon: "internaldrive",
                    label: "磁盘",
                    value: String(format: "%.0f%%", monitor.diskUsage),
                    progress: monitor.diskUsage / 100,
                    color: diskColor
                )
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    private var temperatureColor: Color {
        if monitor.temperature > 80 {
            return .red
        } else if monitor.temperature > 60 {
            return .orange
        }
        return .green
    }

    private var diskColor: Color {
        if monitor.diskUsage > 90 {
            return .red
        } else if monitor.diskUsage > 75 {
            return .orange
        }
        return .purple
    }
}

struct StatItem: View {
    let icon: String
    let label: String
    let value: String
    let progress: Double
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundStyle(color)

                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geometry.size.width * min(progress, 1.0), height: 4)
                }
            }
            .frame(height: 4)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
    }
}

#Preview {
    SystemStatsCard(monitor: SystemMonitor())
        .frame(width: 300)
        .padding()
}
