import SwiftUI

struct WebsiteStatsView: View {
    @Binding var websites: [Website]

    var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {

                    // Highlight Key Metrics
                    HStack(spacing: 20) {
                        KeyMetricView(title: "Total", value: "\(websites.count)", systemImage: "list.bullet")
                        KeyMetricView(title: "Online", value: "\(websites.filter { $0.status == "200" }.count)", systemImage: "globe")
                        KeyMetricView(title: "Offline", value: "\(websites.filter { $0.status != "200" }.count)", systemImage: "xmark.octagon.fill")
                            .foregroundColor(.red) // Highlight offline count in red
                    }

                    // Ping Statistics Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Ping Performance")
                            .font(.title2)
                            .bold()

                        if let avgPing = calculateAveragePing(websites: websites) {
                            StatisticRow(title: "Average Ping", value: "\(String(format: "%.2f", avgPing * 1000)) ms")
                        } else {
                            StatisticRow(title: "Average Ping", value: "N/A")
                        }

                        if let fastestPing = calculateFastestPing(websites: websites) {
                            StatisticRow(title: "Fastest Ping", value: "\(String(format: "%.2f", fastestPing * 1000)) ms")
                        } else {
                            StatisticRow(title: "Fastest Ping", value: "N/A")
                        }

                        if let slowestPing = calculateSlowestPing(websites: websites) {
                            StatisticRow(title: "Slowest Ping", value: "\(String(format: "%.2f", slowestPing * 1000)) ms")
                        } else {
                            StatisticRow(title: "Slowest Ping", value: "N/A")
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)

                    // Status Codes Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Status Codes")
                            .font(.title2)
                            .bold()

                        StatisticRow(title: "Most Common", value: "\(mostFrequentStatusCode(websites: websites) ?? "N/A")")
                        // Potentially add more status code insights here (e.g., distribution chart)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Website Insights")
        }
    

    // Helper view for key metrics
    struct KeyMetricView: View {
        let title: String
        let value: String
        let systemImage: String

        var body: some View {
            VStack {
                Image(systemName: systemImage)
                    .font(.largeTitle)
                Text(value)
                    .font(.title)
                    .bold()
                Text(title)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity) // Expand to fill available space
        }
    }

    // Helper view for statistic rows
    struct StatisticRow: View {
        let title: String
        let value: String

        var body: some View {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text(value)
                    .font(.subheadline)

                    .foregroundColor(.secondary)
            }
        }
    }

    func calculateAveragePing(websites: [Website]) -> TimeInterval? {
            let totalPingTime = websites.flatMap { $0.history.compactMap { $0.pingTime } }.reduce(0, +)
            let totalPings = websites.flatMap { $0.history.compactMap { $0.pingTime } }.count
            return totalPings > 0 ? totalPingTime / Double(totalPings) : nil
        }
    }
    // Calculate fastest ping
    func calculateFastestPing(websites: [Website]) -> TimeInterval? {
        let allPings = websites.flatMap { $0.history.compactMap { $0.pingTime } }
        return allPings.min()
    }

    // Calculate slowest ping
    func calculateSlowestPing(websites: [Website]) -> TimeInterval? {
        let allPings = websites.flatMap { $0.history.compactMap { $0.pingTime } }
        return allPings.max()
    }

    // Find most frequent status code
func mostFrequentStatusCode(websites: [Website]) -> String? {
    let allStatusCodes = websites.flatMap { $0.history.compactMap { $0.statusCode } }

    let statusCodeCounts = allStatusCodes.reduce(into: [Int: Int]()) { counts, statusCode in
        counts[statusCode, default: 0] += 1
    }
    
    if let mostFrequent = statusCodeCounts.max(by: { $0.value < $1.value }) {
        return String(mostFrequent.key)
    } else {
        return nil
    }
}
