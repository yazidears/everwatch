import SwiftUI

struct UptimeOverviewView: View {
    @Binding var websites: [Website]

    var body: some View {
        NavigationView {
            VStack {
                // Overall Uptime Percentage
                if let overallUptime = calculateOverallUptime(websites: websites) {
                    ProgressView(value: overallUptime, total: 100)
                        .progressViewStyle(CircularProgressViewStyle(tint: .green)) // Green for uptime
                        .scaleEffect(1.5) // Make it larger
                        .padding()
                    Text("Overall Uptime: \(String(format: "%.1f", overallUptime))%")
                        .font(.title2)
                } else {
                    Text("No uptime data yet.")
                        .foregroundColor(.secondary)
                }

                // List of websites with their current status and uptime percentage
                List {
                    ForEach(websites) { website in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(website.name)
                                    .font(.headline)
                                Text(website.url)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if let uptime = calculateUptime(for: website) {
                                Text("\(String(format: "%.1f", uptime))%")
                                    .foregroundColor(uptime == 100 ? .green : .red)
                            } else {
                                Text("N/A")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Uptime Overview")
        }
    }

    func calculateOverallUptime(websites: [Website]) -> Double? {
        let onlineWebsites = websites.filter { $0.status == "200" }.count
        return websites.count > 0 ? (Double(onlineWebsites) / Double(websites.count)) * 100 : nil
    }

    func calculateUptime(for website: Website) -> Double? {
        let onlinePeriods = groupStatusPeriods(website.history).filter { $0.status == "200" }
        let totalDuration: TimeInterval = onlinePeriods.reduce(0) { $0 + ($1.endTime?.timeIntervalSince($1.startTime) ?? Date().timeIntervalSince($1.startTime)) }
        let overallDuration: TimeInterval = website.history.last.map { Date().timeIntervalSince($0.timestamp) } ?? 0
        return overallDuration > 0 ? (totalDuration / overallDuration) * 100 : nil
    }
}
